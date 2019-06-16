#!/bin/sh
set -eu

# copy of see .docker-files/entrypoint.sh - testing all versions
version_greater() {
	[ "$(printf '%s\n' "$@" | sort -r -t '-' -k2,2  | sort -t '.' -n -k1,1 -k2,2 -s | head -n 1)" != "$1" ]
}

if ! version_greater "2019.06" "2019.06-rc"; then
	exit 1;
fi
if ! version_greater "2019.06" "2019.04-rc"; then
	exit 1;
fi
if version_greater "2019.06-rc" "2019.06"; then
	exit 1;
fi
if version_greater "2019.04" "2019.06"; then
	exit 1;
fi
if ! version_greater "2019.06" "2019.04"; then
	exit 1;
fi
if ! version_greater "2019.07" "2019.06-rc"; then
	exit 1;
fi
if version_greater "2019.05" "2019.06-rc"; then
	exit 1;
fi
if version_greater "2019.05-dev" "2019.05"; then
	exit 1;
fi
if ! version_greater "2019.05" "2019.05-dev"; then
	exit 1;
fi
