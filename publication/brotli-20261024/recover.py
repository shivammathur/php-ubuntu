"""Recover publication of the already built and audited October 24 caches."""
import concurrent.futures
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time
from urllib.parse import quote

import boto3
from boto3.s3.transfer import TransferConfig
from botocore.config import Config
from botocore.exceptions import ClientError
import requests

ROOT = Path(__file__).parent
REPO = 'shivammathur/php-ubuntu'
BUCKET = 'php-ubuntu'
MANIFEST = json.loads((ROOT / 'manifest.json').read_text())
assert MANIFEST['repo'] == REPO and len(MANIFEST['artifacts']) == 336
assert len(MANIFEST['versions']) == 14 and len(MANIFEST['sources']) == 14
assert len({item['archive'] for item in MANIFEST['artifacts']}) == 336
for item in MANIFEST['artifacts']:
    assert re.fullmatch(r'[0-9a-f]{64}', item['sha256']) and item['size'] > 0
    assert item['archive'].startswith('php_' + item['php'] + '-')
    assert re.fullmatch(r'php_' + re.escape(item['php']) + r'\.[0-9]+(?:[A-Za-z]+[0-9]*)?-(?:nts|zts)(?:-dbgsym)?\+ubuntu(?:22|24|26)\.04(?:_arm64)?\.tar\.zst', item['full_alias'])
RECEIPTS = Path('receipts')
RECEIPTS.mkdir(exist_ok=True)


def save(name, value):
    path = RECEIPTS / name
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2) + '\n')


def request(method, url, **kwargs):
    for attempt in range(5):
        response = requests.request(method, url, timeout=(30, 180), **kwargs)
        if response.status_code not in [429, 500, 502, 503, 504]:
            response.raise_for_status()
            return response
        response.close()
        time.sleep(5 * (attempt + 1))
    raise RuntimeError('HTTP request exhausted retries')


def github(path, method='GET'):
    return request(method, 'https://api.github.com/repos/' + REPO + '/' + path,
                   headers={'Authorization': 'Bearer ' + os.environ['GH_TOKEN'],
                            'Accept': 'application/vnd.github+json'})


def public_digest(url, destination=None):
    digest = hashlib.sha256()
    size = 0
    output = destination.open('wb') if destination else None
    try:
        with request('GET', url, stream=True) as response:
            for chunk in response.iter_content(1024 * 1024):
                digest.update(chunk)
                size += len(chunk)
                if output:
                    output.write(chunk)
    finally:
        if output:
            output.close()
    return digest.hexdigest(), size


def s3_client(prefix):
    return boto3.client('s3', endpoint_url=os.environ[prefix + '_AWS_S3_ENDPOINT'],
                        aws_access_key_id=os.environ[prefix + '_AWS_ACCESS_KEY_ID'],
                        aws_secret_access_key=os.environ[prefix + '_AWS_SECRET_ACCESS_KEY'],
                        region_name='us-east-1',
                        config=Config(signature_version='s3v4', retries={'max_attempts': 4},
                                      request_checksum_calculation='when_required',
                                      response_checksum_validation='when_required'))


def s3_digest(client, name):
    try:
        response = client.get_object(Bucket=BUCKET, Key=name)
    except ClientError as error:
        if error.response['Error']['Code'] in ['NoSuchKey', '404']:
            return None
        raise
    with response['Body'] as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def mirror(path, expected, prefix):
    client = s3_client(prefix)
    previous = s3_digest(client, path.name)
    if previous != expected:
        client.upload_file(str(path), BUCKET, path.name,
                           ExtraArgs={'Metadata': {'sha256': expected}},
                           Config=TransferConfig(max_concurrency=2))
        assert s3_digest(client, path.name) == expected, (prefix, path.name)
    return {'sha256': expected, 'action': 'matching' if previous == expected else 'uploaded'}


def cloudsmith_packages(name):
    result = []
    for page in range(1, 100):
        response = request('GET', f'https://api.cloudsmith.io/v1/packages/{REPO}/',
                           params={'query': 'filename:' + name, 'page_size': 100, 'page': page})
        packages = response.json()
        result.extend(p for p in packages if p['filename'] == name)
        if len(packages) < 100:
            return result
    raise RuntimeError('Cloudsmith pagination exceeded bounds')


def cloudsmith(path, expected):
    for attempt in range(3):
        packages = cloudsmith_packages(path.name)
        matching = [p for p in packages if p['checksum_sha256'] == expected and p['is_sync_completed']]
        if matching:
            return {'sha256': expected, 'package': matching[0]['slug_perm']}
        subprocess.run(['cloudsmith', 'push', 'raw', REPO, str(path), '--republish',
                        '--summary', path.name, '--description', path.name], check=False)
        time.sleep(5)
    packages = cloudsmith_packages(path.name)
    matching = [p for p in packages if p['checksum_sha256'] == expected and p['is_sync_completed']]
    assert matching, path.name
    return {'sha256': expected, 'package': matching[0]['slug_perm']}


def github_assets():
    return {a['name']: a for a in github('releases/tags/builds').json()['assets']}


def assert_github(item, assets):
    for name in [item['archive'], item['full_alias']]:
        asset = assets[name]
        assert asset['state'] == 'uploaded' and asset['size'] == item['size']
        assert asset['digest'] == 'sha256:' + item['sha256'], name


def publish(version):
    items = [x for x in MANIFEST['artifacts'] if x['php'] == version]
    assert len(items) == 24
    assets = github_assets()
    directory = Path('downloads')
    directory.mkdir(exist_ok=True)

    def one(item):
        assert_github(item, assets)
        path = directory / item['archive']
        url = f'https://github.com/{REPO}/releases/download/builds/' + quote(path.name)
        assert public_digest(url, path) == (item['sha256'], item['size'])
        result = {'artifact_id': item['artifact_id'], 'archive': path.name, 'sha256': item['sha256'],
                  'full_alias': item['full_alias'], 'github': 'verified'}
        for prefix in ['SETUP_PHP', 'CF_R2']:
            result[prefix] = mirror(path, item['sha256'], prefix)
        result['cloudsmith'] = cloudsmith(path, item['sha256'])
        if item.get('repaired_alias'):
            corrected = Path('corrected') / item['artifact']
            corrected.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(path, corrected / path.name)
            os.link(corrected / path.name, corrected / item['full_alias'])
        path.unlink()
        save(f'items/{version}/{item["artifact_id"]}.json', result)
        print(json.dumps({'php': version, 'archive': item['archive'], 'publication': 'verified'}), flush=True)
        return result

    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(one, items))
    save(f'publication-{version}.json', {'php': version, 'manifest_sha256': MANIFEST_HASH, 'results': results})


def finalize():
    records = [json.loads(p.read_text()) for p in Path('input-receipts').rglob('publication-*.json')]
    assert {r['php'] for r in records} == set(MANIFEST['versions']) and len(records) == 14
    for record in records:
        assert record['manifest_sha256'] == MANIFEST_HASH and len(record['results']) == 24
        expected = {i['artifact_id']: i['sha256'] for i in MANIFEST['artifacts'] if i['php'] == record['php']}
        assert {i['artifact_id']: i['sha256'] for i in record['results']} == expected
    for source in MANIFEST['sources']:
        run = github(f'actions/runs/{source["run"]}').json()
        assert run['head_sha'] == source['head'] and run['status'] == 'completed'

    installer = Path('scripts/install.sh')
    expected = MANIFEST['installer_sha256']
    assert hashlib.sha256(installer.read_bytes()).hexdigest() == expected
    assets = github_assets()
    if assets.get(installer.name, {}).get('digest') != 'sha256:' + expected:
        subprocess.run(['gh', 'release', 'upload', 'builds', str(installer), '--repo', REPO, '--clobber'], check=True)
    assert github_assets()[installer.name]['digest'] == 'sha256:' + expected
    metadata = {}
    for prefix in ['SETUP_PHP', 'CF_R2']:
        metadata[prefix] = mirror(installer, expected, prefix)
    cloudsmith_installer = Path('php-ubuntu.sh')
    shutil.copyfile(installer, cloudsmith_installer)
    metadata['cloudsmith'] = cloudsmith(cloudsmith_installer, expected)

    removed = []
    for name, allowed in MANIFEST['malformed_names'].items():
        assert name in ['php_-zts+ubuntu22.04_arm64.tar.zst', 'php_-zts-dbgsym+ubuntu22.04_arm64.tar.zst']
        asset = assets.get(name)
        if asset:
            assert asset['digest'].removeprefix('sha256:') in allowed
            github(f'releases/assets/{asset["id"]}', 'DELETE')
        for package in cloudsmith_packages(name):
            assert package['checksum_sha256'] in allowed
            request('DELETE', f'https://api.cloudsmith.io/v1/packages/{REPO}/{package["slug_perm"]}/',
                    headers={'X-Api-Key': os.environ['CLOUDSMITH_API_KEY']})
        assert not cloudsmith_packages(name)
        for prefix in ['SETUP_PHP', 'CF_R2']:
            client = s3_client(prefix)
            digest = s3_digest(client, name)
            if digest is not None:
                assert digest in allowed
                client.delete_object(Bucket=BUCKET, Key=name)
            assert s3_digest(client, name) is None
        removed.append(name)
    assert not set(MANIFEST['malformed_names']) & github_assets().keys()
    purge = request('POST', f'https://api.cloudflare.com/client/v4/zones/{os.environ["CF_CACHE_ZONE"]}/purge_cache',
                    headers={'Authorization': 'Bearer ' + os.environ['CF_CACHE_KEY']},
                    json={'tags': ['php-ubuntu']}).json()
    assert purge['success']
    metadata['public_urls'] = []
    for url in [f'https://github.com/{REPO}/releases/download/builds/install.sh',
                'https://artifacts.php-ubuntu.setup-php.com/install.sh',
                'https://artifacts.setup-php.com/php-ubuntu/install.sh',
                f'https://dl.cloudsmith.io/public/{REPO}/raw/files/php-ubuntu.sh']:
        verify_public(url, expected, installer.stat().st_size)
        metadata['public_urls'].append(url)
    save('finalization.json', {'manifest_sha256': MANIFEST_HASH, 'metadata': metadata,
                              'removed_malformed_names': removed, 'cdn_purged': True})


def verify_public(url, expected, size):
    for attempt in range(5):
        try:
            if public_digest(url) == (expected, size):
                return
        except requests.HTTPError as error:
            if error.response.status_code != 404:
                raise
        time.sleep(15)
    raise AssertionError('Public download mismatch: ' + url)


def verify(version):
    items = [x for x in MANIFEST['artifacts'] if x['php'] == version]
    assert len(items) == 24
    assets = github_assets()
    bases = ['https://artifacts.php-ubuntu.setup-php.com/',
             'https://artifacts.setup-php.com/php-ubuntu/',
             f'https://dl.cloudsmith.io/public/{REPO}/raw/files/']

    def one(item):
        assert_github(item, assets)
        result = {'artifact_id': item['artifact_id'], 'archive': item['archive'], 'sha256': item['sha256'], 'urls': []}
        for base in bases:
            url = base + quote(item['archive'])
            verify_public(url, item['sha256'], item['size'])
            result['urls'].append(url)
        save(f'public-items/{version}/{item["artifact_id"]}.json', result)
        print(json.dumps({'php': version, 'archive': item['archive'], 'public_mirrors': 'verified'}), flush=True)
        return result

    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        results = list(pool.map(one, items))
    save(f'public-{version}.json', {'php': version, 'manifest_sha256': MANIFEST_HASH, 'results': results})


MANIFEST_HASH = hashlib.sha256((ROOT / 'manifest.json').read_bytes()).hexdigest()
if __name__ == '__main__':
    mode = sys.argv[1]
    if mode == 'publish':
        publish(sys.argv[2])
    elif mode == 'finalize':
        finalize()
    elif mode == 'verify':
        verify(sys.argv[2])
    else:
        raise ValueError(mode)
