#!/usr/bin/env bash

. /etc/os-release

if [ ${NIGHTLY:?} = 'true' ] || [ ${TS:?} = 'zts' ] || [ "$VERSION_ID" = "24.04" ]; then
  echo php-builder;
else
  echo 'packages';
fi
