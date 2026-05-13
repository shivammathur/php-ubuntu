#!/usr/bin/env python

import apt_pkg
from fnmatch import fnmatchcase
from pathlib import Path

def parse(file):
  tag_obj = apt_pkg.TagFile(open(file, "r"))
  listings={}
  while tag_obj.step() == 1:
      listings[tag_obj.section.get("Package")] = str(tag_obj.section) + "\n"
  return listings

def package_list(file):
  path = Path(file)
  if not path.is_file():
    return []

  return [line.strip() for line in path.read_text().splitlines() if line.strip()]

def package_matches(package, patterns):
  return any(fnmatchcase(package, pattern) for pattern in patterns)

def has_package_info(package, value):
  info_dir = Path('/tmp/php/var/lib/dpkg/info')
  if not info_dir.is_dir():
    return False

  for line in value.splitlines():
    if line.startswith('Architecture: '):
      arch = line.split(': ', 1)[1]
      break
  else:
    arch = ''

  if (info_dir / f'{package}.list').is_file():
    return True

  return arch not in ('', 'all') and (info_dir / f'{package}:{arch}.list').is_file()

status = '/var/lib/dpkg/status'
old_status = status + '-orig'
listing = parse(status)
old_listing = parse(old_status)
required = package_list('/tmp/required')
excluded = package_list('/tmp/excluded')

new_listing={}
for key, value in listing.items():
  if package_matches(key, excluded):
    continue

  if (
    key not in old_listing or listing[key] != old_listing[key] or key in required
  ) and has_package_info(key, value):
    new_listing[key] = value

dff = open(status + '-diff', "w")
for key in sorted(new_listing):
    dff.write(new_listing[key])
