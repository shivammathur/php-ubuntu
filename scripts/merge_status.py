#!/usr/bin/env python

import apt_pkg

def parse(file):
  tag_obj = apt_pkg.TagFile(open(file, "r"))
  listings={}
  while tag_obj.step() == 1:
      listings[tag_obj.section.get("Package")] = str(tag_obj.section) + "\n"
  return listings

status = '/var/lib/dpkg/status-diff'
old_status = '/var/lib/dpkg/status-orig'
listing = parse(status)
old_listing = parse(old_status)

for key, value in listing.items():
  old_listing[key] = value

olf = open(old_status, "a")
olf.seek(0)
olf.truncate()
for key in old_listing:
    olf.write(old_listing[key])
