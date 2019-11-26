#!/bin/sh
set -eu

# checks if the branch and repository exists
check_branch() {
  repo=${1:-}
  branch=${2:-}
  git ls-remote --heads --tags "https://github.com/$repo" | grep -E "refs/(heads|tags)/${branch}$" >/dev/null
  [ "$?" -eq "0" ]
}

# clones the whole develop branch (Friendica and Addons)
clone_develop() {
	friendica_git="${FRIENDICA_VERSION}"
	addons_git="${FRIENDICA_ADDONS}"
	friendica_repo="${FRIENDICA_REPOSITORY:-friendica/friendica}"
	friendica_addons_repo="${FRIENDICA_ADDONS_REPO:-friendica/friendica-addons}"

	if echo "{$friendica_git,,}" | grep -Eq '^.*\-dev'; then
		friendica_git="develop"
	fi

	if echo "{$addons_git,,}" | grep -Eq '^.*\-dev'; then
		addons_git="develop"
	fi

  # Check if the branches exist before wiping the
	if check_branch "$friendica_repo" "$friendica_git" && check_branch "$friendica_addons_repo" "$addons_git" ; then
    echo "Cloning '${friendica_git}' from GitHub repository '${friendica_repo}' ..."

    # Removing the whole directory first
    rm -fr /usr/src/friendica
    git clone -q -b ${friendica_git} "https://github.com/${friendica_repo}" /usr/src/friendica

    mkdir /usr/src/friendica/addon
    git clone -q -b ${addons_git} "https://github.com/${friendica_addons_repo}" /usr/src/friendica/addon

    echo "Download finished"

    if [ ! -f /usr/src/friendica/VERSION ]; then
      echo "Couldn't clone repository"
      exit 1
    fi

    /usr/src/friendica/bin/composer.phar install --no-dev -d /usr/src/friendica
    return 0

  else
    if check_branch "$friendica_repo" "$friendica_git"; then
      echo "$friendica_repo/$friendica_git is not valid."
    else
      echo "$friendica_addons_repo/$addons_git is not valid."
    fi
    echo "Using old version."
    return 1

  fi
}

# just check if we execute apache or php-fpm
if expr "$1" : "apache" 1>/dev/null || [ "$1" = "php-fpm" ]; then
	# cloning from git is just possible for develop or Release Candidats
	if echo "${FRIENDICA_VERSION}" | grep -Eq '^.*(\-dev|-rc|-RC)' || [ "${FRIENDICA_UPGRADE:-false}" = "true" ] || [ ! -f /usr/src/friendica/VERSION ]; then
		# just clone & check if it's a new install or upgrade
		clone_develop
	fi
fi

/entrypoint.sh "$@"
