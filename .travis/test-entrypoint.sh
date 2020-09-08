#!/bin/sh
set -eu

# copy of see .docker-files/entrypoint.sh - testing all versions
version_greater() {
	[ "$(printf '%s\n' "$@" | sed -e 's/-rc/.1/' | sed -e 's/-dev/.2/' | sort -t '.' -k1,1n -k2,2n -k3,3nbr | head -n 1)" != "$(printf "$1" | sed -e 's/-rc/.1/' | sed -e 's/-dev/.2/')" ]
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
if ! version_greater "2020.07-1" "2020.07"; then
  exit 1;
fi
if ! version_greater "2020.07-2" "2020.07-1"; then
  exit 1;
fi
if ! version_greater "2020.07-1" "2020.07-dev"; then
  exit 1;
fi
if ! version_greater "2020.09-rc" "2020.09-dev"; then
	exit 1
fi
if version_greater "2020.06-rc" "2020.09-dev"; then
	exit 1;
fi
