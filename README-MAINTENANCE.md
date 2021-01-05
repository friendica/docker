# How to maintain this repository

The structure and usage of this repository is influenced by other, official docker repositories.

# Version directories

**This is important!**

The `update.sh` script automatically deletes all non-`.`-directories (= version directories) at first.

Never ever change a file/folder inside a directory without a `.` at the beginning (`2018.05-rc`, ...).
This folder will get updated automatically based on the templates you want to change.
All changes in such folders will get overwritten during an update.

# How to update

This section describes how to update the official Friendica docker images.
The official Docker image is available at https://hub.docker.com/_/friendica.

## How to update the Docker Image

1. Review your changes based on the official Docker [Review guidelines](https://github.com/docker-library/official-images#review-guidelines). 
2. Check for a new stable version (see chapter `generate-stackbrew-library.sh`)
3. Check if you have to adjust the minimum version (see chapter `update.sh`)
4. Check if all tests are green (common issue: you forgot to commit all changes because of `update.sh`)
5. Check if all commits are available at the stable branch (= all required PRs are committed into stable)
6. Download & install [`bashbrew`](https://github.com/docker-library/bashbrew)
7. Execute `generate-stackbrew-library.sh`
8. Copy the output & overwrite the whole official Friendica [docker manifest](https://github.com/docker-library/official-images/blob/master/library/friendica).
9. Create a new PR at https://github.com/docker-library/official-images/pulls

After the PR is merged, the images aren't immediately available, they've to get build.
Check the official Docker Continuous Deployment server https://doi-janky.infosiftr.net/job/multiarch/ for the current status of the builds.

## How to update the docker hub description

1. At first, read https://github.com/docker-library/docs#how-do-i-update-an-images-docs
2. Checkout & change the content of https://github.com/docker-library/docs/tree/master/friendica
3. Create a new Pull Request at https://github.com/docker-library/docs/pulls 

# Tools & Scripts

## Github Action

GitHub Actions helps to automate tasks for Continuous Integration (= autotest Docker images) and Continuous Deployment (= autocreate Docker images based on the friendica upstream).

For mor details see [Introduction to github actions](https://docs.github.com/en/free-pro-team@latest/actions/learn-github-actions/introduction-to-github-actions).

### [`update-sh.yml`](https://github.com/friendica/docker/blob/stable/.github/workflows/update-sh.yml)

This script is a cronjob every 15 minutes and automatically runs `update.sh`.
In case there are changes because of `update.sh`, it starts `images.yml`.

### [`images.yml`](https://github.com/friendica/docker/blob/stable/.github/workflows/images.yml)

This script automatically creates autotests actions based on the Docker image version structure and variants.
For example if there are two versions (like `2021.03-dev` and `2021.01`), it would create 3 runs (apache, apache-fpm, fpm-alpine) for each version, having 6 runs at all.

The script uses the official docker GitHub Action tool [`bashbrew`](https://github.com/docker-library/bashbrew.git) to transform the repository version structure into GitHub Action commands.

This workflow is automatically executed because of a PR, a commit to `stable` or if the cronjob has found new updates.

## Maintenance scripts

### [`update.sh`](https://github.com/friendica/docker/blob/stable/update.sh)
   
Creates a directory, and the necessary files for each combination of version (2018.05-rc, 3.6, ...) and variant (apache, fpm, fpm-alpine):

- Creating the right `Dockerfile` (from one of the two *.template files)
- Copy each config file in `.config/`
- Recreating the version/variant environment in `.travis.yml` 

All possible Friendica versions are retrieved from https://files.friendi.ca/.

#### Version patterns

The update script parses the source https://files.friendi.ca/ automatically based on these patterns:
- stable: `friendica-full-%YYYY%.%MM%.tar.gz` (e.g. `friendica-full-2021.10.tar.gz`)
- dev/rc: `friendica-full-%YYYY%.%MM%-dev/rc.tar.gz` (e.g. `friendica-full-2021.10-dev.tar.gz`)
- hotfix: `friendica-full-%YYYY%.%MM%-%i.tar.gz` (e.g. `friendica-full-2021.10-01.tar.gz`)
   
Any other pattern will completely be ignored(!)

#### Minimum version

Please adjust the `min_version` variable.
It contains the minimum supported version, which will automatically be available as a Docker image.
Any other versions lower than this won't be available from the official Docker Hub anymore.

### [`generate-stackbrew-library.sh`](https://github.com/friendica/docker/blob/stable/generate-stackbrew-library.sh)

This file creates a "manifest" for the docker-images.
This "manifest" is used to create a new PR in the official-images [repository](https://github.com/docker-library/official-images/) for deploying the changes to the Docker Hub.
Like:

```console   
# This file is generated via https://github.com/friendica/docker/blob/b46fae917321394e1482df59dc4e39daffbe5c59/generate-stackbrew-library.sh
Maintainers: Friendica <info@friendi.ca> (@friendica), Philipp Holzer <admin@philipp.info> (@[secure])
GitRepo: https://github.com/friendica/docker.git

Tags: 2018.05-rc-apache, rc-apache, apache, stable-apache, production-apache, 2018.05-rc, rc, latest, stable, production
Architectures: amd64, arm32v5, arm32v7, arm64v8, i386, ppc64le, s390x
GitCommit: b46fae917321394e1482df59dc4e39daffbe5c59
Directory: 2018.05-rc/apache

Tags: 2018.05-rc-fpm, rc-fpm, fpm, stable-fpm, production-fpm
Architectures: amd64, arm32v5, arm32v7, arm64v8, i386, ppc64le, s390x
GitCommit: b46fae917321394e1482df59dc4e39daffbe5c59
Directory: 2018.05-rc/fpm

Tags: 2018.05-rc-fpm-alpine, rc-fpm-alpine, fpm-alpine, stable-fpm-alpine, production-fpm-alpine
Architectures: amd64, arm32v6, arm64v8, i386, ppc64le, s390x
GitCommit: b46fae917321394e1482df59dc4e39daffbe5c59
Directory: 2018.05-rc/fpm-alpine
This is the input-file for the official-images in a later step :-)
```

#### Release channels

Please adjust the `release_channel` array.
It maps additional tags onto Docker image versions.
Most important is the `stable` tag.
