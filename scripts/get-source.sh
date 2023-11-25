#!/usr/bin/env bash

if [ ${NIGHTLY:?} = 'true' ] || [ ${TS:?} = 'zts' ]; then
  echo php-builder;
else
  echo 'packages';
fi
