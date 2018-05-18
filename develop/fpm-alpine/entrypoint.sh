#!/bin/sh
set -eu

# Check if Friendica needs to get installed
friendica install

exec "$@"