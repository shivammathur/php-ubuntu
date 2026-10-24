import hashlib
import json
import os
from pathlib import Path
import subprocess

import boto3
from boto3.s3.transfer import TransferConfig
from botocore.config import Config
from botocore.exceptions import ClientError

NAME = 'php_5.6-nts-dbgsym+ubuntu22.04.tar.zst'
SHA256 = 'a8e97e0097d864ccdb604e833c710f47f81f8af9bdde5c99d803dcef88dd0068'
subprocess.run(['gh', 'release', 'download', 'builds', '--repo', 'shivammathur/php-ubuntu',
                '--pattern', NAME], check=True)
with Path(NAME).open('rb') as stream:
    assert hashlib.file_digest(stream, 'sha256').hexdigest() == SHA256
results = []
for prefix in ['SETUP_PHP', 'CF_R2']:
    for mode in ['when_supported', 'when_required', 'single_put']:
        client = boto3.client(
            's3', endpoint_url=os.environ[prefix + '_AWS_S3_ENDPOINT'],
            aws_access_key_id=os.environ[prefix + '_AWS_ACCESS_KEY_ID'],
            aws_secret_access_key=os.environ[prefix + '_AWS_SECRET_ACCESS_KEY'],
            region_name='us-east-1',
            config=Config(signature_version='s3v4', retries={'max_attempts': 2},
                          request_checksum_calculation='when_required' if mode == 'single_put' else mode,
                          response_checksum_validation='when_required'))
        result = {'destination': prefix, 'mode': mode, 'name': NAME, 'sha256': SHA256}
        try:
            client.upload_file(NAME, 'php-ubuntu', NAME,
                               ExtraArgs={'Metadata': {'sha256': SHA256}},
                               Config=TransferConfig(multipart_threshold=5 * 1024**3 if mode == 'single_put' else 8 * 1024**2,
                                                     max_concurrency=2))
            body = client.get_object(Bucket='php-ubuntu', Key=NAME)['Body']
            with body:
                digest = hashlib.file_digest(body, 'sha256').hexdigest()
            assert digest == SHA256
            result['result'] = 'upload_and_download_verified'
        except Exception as error:
            result['result'] = 'failed'
            result['exception'] = type(error).__name__
            cause = error
            while cause.__context__ is not None:
                cause = cause.__context__
            if isinstance(cause, ClientError):
                result['operation'] = cause.operation_name
                result['code'] = cause.response['Error']['Code']
                result['http_status'] = cause.response['ResponseMetadata']['HTTPStatusCode']
        results.append(result)
        Path('s3-diagnosis.json').write_text(json.dumps(results, indent=2) + '\n')
        print(json.dumps(result), flush=True)
        if mode == 'when_required' and result['result'] == 'upload_and_download_verified':
            break
assert all(any(item['destination'] == prefix and item['result'] == 'upload_and_download_verified'
               for item in results) for prefix in ['SETUP_PHP', 'CF_R2'])
