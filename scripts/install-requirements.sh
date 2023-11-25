#!/usr/bin/env bash

source=$(bash ./scripts/get-source.sh)

bash ./scripts/install-requirements-$source.sh
