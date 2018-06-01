#!/bin/sh
set -eu

friendica install -q
friendica sendmail -q

exec "$@"