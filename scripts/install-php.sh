#!/usr/bin/env bash

source=$(bash ./scripts/get-source.sh)
echo "$source" > /tmp/php-ubuntu-source

bash ./scripts/install-php-$source.sh
