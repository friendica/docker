#!/bin/sh
set -eu

friendica install -q
friendica configmail -q

exec "$@"