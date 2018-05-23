#!/bin/sh
set -eu

friendica install -q
friendica patch -q
friendica sendmail -q

exec "$@"