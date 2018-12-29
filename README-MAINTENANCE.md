# How to maintain this repository

The structure and usage of this repository is influenced by other, official docker repositories.

# Version directories

**This is important!**

Never ever change a file/folder inside a directory without a `.` at the beginning (`2018.05-rc`, ...).
This folder will get updated automatically based on the templates you want to change.
All changes in such folders will get overwritten during an update.

# Maintenance scripts

# `update.sh`
   
Creates a directory and the necessary files for each combination of version (2018.05-rc, 3.6, ...) and variant (apache, fpm, fpm-alpine):

- Creating the right `Dockerfile` (from one of the two *.template files)
- Copy each shell and *.exclude file in `.docker-files/`
- Recreating the version/variant environment in `.travis.yml` 
   
If you want to update the Docker-images to a newer version, just change the list in `update.sh` at
```shell
versions=(
  2018.05-rc
)
```
   
# `generate-stackbrew-library.sh`
   
This file automatically creates a "manifest" for the docker-images.
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

# `build_and_push.sh`

This file automatically builds and publish all docker image variants (apache, fpm, ...) and versions (stable, latest, dev, ...)

It uses [bashbrew](https://github.com/docker-library/official-images/tree/master/bashbrew) for building and publishing and `generate-stackbrew-library.sh` for the definition (manifest) what to build and publish.

See [Instruction format](https://github.com/docker-library/official-images/blob/master/README.md#instruction-format) for more background information.