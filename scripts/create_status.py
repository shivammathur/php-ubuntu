#!/usr/bin/env python

import apt_pkg

def parse(file):
  tag_obj = apt_pkg.TagFile(open(file, "r"))
  listings={}
  while tag_obj.step() == 1:
      listings[tag_obj.section.get("Package")] = str(tag_obj.section) + "\n"
  return listings

status = '/var/lib/dpkg/status'
old_status = status + '-orig'
listing = parse(status)
old_listing = parse(old_status)

required = ['libpcre16-3', 'libpcre2-8-0', 'libpcre2-16-0', 'libpcre2-32-0', 'libpcre2-dev', 'libpcre2-posix3', 'libpcre3', 'libpcre3-dev', 'libpcre32-3', 'libpcrecpp0v5']

new_listing={}
for key, value in listing.items():
  if key not in old_listing or listing[key] != old_listing[key] or key in required:
    new_listing[key] = value

dff = open(status + '-diff', "w")
for key in sorted(new_listing):
    dff.write(new_listing[key])
