# Docker Image for Friendica
[![Build Status Travis](https://travis-ci.org/friendica/docker.svg?branch=master)](https://travis-ci.org/friendica/docker)

This repository holds the official Docker Image for [Friendica](https://friendi.ca)

# What is Friendica?

Friendica is a decentralised communications platform that integrates social communication.
Our platform links to independent social projects and corporate services.

![logo](https://cdn.rawgit.com/friendica/docker/9c954f4d/friendica.svg)

# How to use this image

The images are designed to be used in a micro-service environment.		
There are two types of the image you can choose from.

The `apache` tag contains a full Friendica installation including an apache web server.
It is designed to be easy to use and gets you running pretty fast.
This is also the default for the `latest` tag and version tags that are not further specified.

The second option is a `fpm` container.
It is based on the [php-fpm](https://hub.docker.com/_/php/) image and runs a fastCGI-Process that serves your Friendica server.
To use this image it must be combined with any Webserver that can proxy the http requests to the FastCGI-port of the container.

## Using the apache image

You need at least one other mariadb/mysql-container to link it to Friendica.

The apache image contains a webserver and exposes port 80.
To start the container type:

```console
$ docker run -d -p 8080:80 --link some-mysql:mysql friendica
```

Now you can access the Friendica installation wizard at http://localhost:8080/ from your host system.

## Using the fpm image

To use the fpm image you need an additional web server that can proxy http-request to the fpm-port of the container.
For fpm connection this container exposes port 9000.
In most cases you might want use another container or your host as proxy.
If you use your host you can address your Friendica container directly on port 9000.
If you use another container, make sure that you add them to the same docker network (via `docker run --network <NAME> ...` or a `docker-compose` file).
In both cases you don't want to map the fpm port to you host.

```console
$ docker run -d friendica/server:fpm
```

As the fastCGI-Process is not capable of serving static files (style sheets, images, ...) the webserver needs access to these files.
This can be achieved with the `volumes-from` option.
You can find more information in the docker-compose section.

## Using the cron job

There are three options to enable the cron-job for Friendica:

-	Using the default Image and activate the cron-job (see [Installation](https://friendi.ca/resources/installation/), sector `Activating scheduled tasks`)
-	Using the default image (apache, fpm, fpm-alpine) and creating **two** container (one for cron and one for the main app)
-	Using one of the additional, prepared [`cron dockerfiles`](https://github.com/friendica/docker/tree/master/.examples/dockerfiles/cron)

## Using sendmail for E-Mail support

You have to set the `--hostname/-h` parameter correctly to make the `mail()` command use the right domainname of it's e-mail.
Currently, the command `sendmail` will be used for the `mail()` support of Friendica.

Be aware that in production environment, you normally have an external MTA (or a SmartHost) for correctly signing and routing your e-mails.
See the Dockerfiles at [`smtp`](https://github.com/friendica/docker/tree/master/.examples/dockerfiles/smtp) for examples how to configure it.

### `apache` and `fpm` image

`sendmail` is used as a SMTP MTA for standalone usage and it works out-of-the-box.

### `fpm-alpine` image

For alpine, there is no "standalone" mail-service available.
Therefore you **have** to setup a SMTP MTA.

## Using an external database

By default the `latest` container uses a local MySQL-Database for data storage, but the Friendica setup wizard (appears on first run) allows connecting to an existing MySQL/MariaDB database.
You can also link a database container, e. g. `--link my-mysql:mysql`, and then use `mysql` as the database host on setup.

## Persistent data

The Friendica installation and all data beyond what lives in the database (file uploads, etc) is stored in the [unnamed docker volume](https://docs.docker.com/engine/tutorials/dockervolumes/#adding-a-data-volume) volume `/var/www/html`.
The docker daemon will store that data within the docker directory `/var/lib/docker/volumes/...`.
That means your data is saved even if the container crashes, is stopped or deleted.

To make your data persistent to upgrading and get access for backups is using named docker volume or mount a host folder.
To achieve this you need one volume for your database container and Friendica.

Friendica:

-	`/var/www/html/` folder where all Friendica data lives

```console
$ docker run -d \
  -v friendica-vol-1:/var/www/html \
  friendica/server
```

Database:

-	`/var/lib/mysql` MySQL / MariaDB Data

```console
$ docker run -d \
  -v mysql-vol-1:/var/lib/mysql \
  mariadb
```

## Auto configuration via environment variables

The Friendica image supports auto configuration via environment variables.
You can preconfigure everything that is asked on the install page on first run.

-	`AUTOINSTALL` if `true`, the automatic configuration will start (Default: `false`)

**MYSQL/MariaDB**:

-	`MYSQL_USERNAME` Username for the database user using mysql / mariadb.
-	`MYSQL_PASSWORD` Password for the database user using mysql / mariadb.
-	`MYSQL_DATABASE` Name of the database using mysql / mariadb.
-	`MYSQL_HOST` Hostname of the database server using mysql / mariadb.
-	`MYSQL_PORT` Port of the database server using mysql / mariadb.

You can also predefine the following `.htconfig.php` values:

-	`MAILNAME` E-Mail address of the administrator
-	`TZ` The default localization of the Friendica server
-	`LANGUAGE` The default language of the Friendica server
-	`SITENAME` The default name of the Friendica server

## Updating to a newer version

There are differences between the [stable](https://github.com/friendica/docker/tree/master/stable/) and the [develop](https://github.com/friendica/docker/tree/master/develop/) branches.

They have both in common that normally we do not automatically overwrite your working directory with the new version.
Instead you need to explicit run `friendica update` for the node for updating files&database.

## Updating stable

You have to pull the latest image from the hub (`docker pull friendica`).

## Updating develop

You don't need to pull the image for each commit in [friendica](https://github.com/friendica/friendica/).
Instead you can just update your node with executing `friendica update` on the node.
Example:

```console
$ docker exec -ti friendica_running_node friendica update
```

It will clone the latest Friendica version and copy it to your working directory.

# The `friendica` CLI

To make the usage of the Docker images smooth, we created a little CLI.
It wraps the common commands for Friendica and adds new commands.

You can call it with

```console
$ docker exec -ti friendica_running_node friendica <command>
```

Commands:

-	`console` Executes an command in the Friendica console (`bin/console.php` wrapper)
-	`composer` Executes the composer.phar executable for Friendica (`bin/composer.phar` wrapper)
-	`install` Installs Friendica on a empty environment (gets called automatically during first start)
-	`update` Updates Friendica on a **existing** environment

# Running this image with docker-compose

The easiest way to get a fully featured and functional setup is using a `docker-compose` file.
There are too many different possibilities to setup your system, so here are only some examples what you have to look for.

At first make sure you have chosen the right base image (fpm or apache) and added the features you wanted (see below).
In every case you want to add a database container and docker volumes to get easy access to your persistent data.
When you want your server reachable from the internet adding HTTPS-encryption is mandatory!
See below for more information.

## Base version - apache

This version will use the apache image and add a mariaDB container.
The volumes are set to keep your data persistent.
This setup provides **no ssl encryption** and is intended to run behind a proxy.

Make sure to set the variable `MYSQL_PASSWORD` before run this setup.

```yaml
version: '2'

services:
  db:
    image: mariadb
    restart: always
    volumes:
      - db:/var/lib/mysql
    environment:
      - MYSQL_USER=friendica
      - MYSQL_PASSWORD=
      - MYSQL_DATABASE=friendica
      - MYSQL_RANDOM_ROOT_PASSWORD=yes

  app:
    image: friendica/server
    restart: always
    volumes:
      - friendica:/var/www/html
    ports:
      - "8080:80"
    environment:
      - MYSQL_HOST=db
      - MYSQL_PORT=3306
      - MYSQL_USER=friendica
      - MYSQL_PASSWORD=
      - MYSQL_DATABASE=friendica
      - MAILNAME=root@friendica.local
    hostname: friendica.local
    depends_on:
      - db

volumes:
  db:
  friendica:
```

Then run `docker-compose up -d`, now you can access Friendica at http://localhost:8080/ from your system.

## Base version - FPM

When using the FPM image you need another container that acts as web server on port 80 and proxies requests to the Friendica container.
In this example a simple nginx container is combined with the Friendica-fpm image and a MariaDB database container.
The data is stored in docker volumes.
The nginx container also need access to static files from your Friendica installation.
It gets access to all the volumes mounted to Friendica via the `volumes_from` option.
The configuration for nginx is stored in the configuration file `nginx.conf` that is mounted into the container.

An example can be found in the [examples section](https://github.com/friendica/docker/tree/master/.examples).

As this setup does **not include encryption** it should to be run behind a proxy.

Maker sure to set the variable `MYSQL_PASSWORD` before you run the setup.

```yaml
version: '2'

services:
  db:
    image: mariadb
    restart: always
    volumes:
      - db:/var/lib/mysql
    environment:
      - MYSQL_USER=friendica
      - MYSQL_PASSWORD=
      - MYSQL_DATABASE=friendica
      - MYSQL_RANDOM_ROOT_PASSWORD=yes

  app:
    image: friendica/server:fpm
    restart: always
    volumes:
      - friendica:/var/www/html    
    environment:
      - MYSQL_HOST=db
      - MYSQL_PORT=3306
      - MYSQL_USER=friendica
      - MYSQL_PASSWORD=
      - MYSQL_DATABASE=friendica
      - MAILNAME=root@friendica.local
    hostname: friendica.local
    depends_on:
      - db

  web:
    image: nginx
    ports:
      - 8080:80
    links:
      - app
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    volumes_from:
      - app
    restart: always

volumes:
  db:
  friendica:
```

Then run `docker-compose up -d`, now you can access Friendica at http://localhost:8080/ from your system.

# Questions / Issues

If you got any questions or problems using the image, please visit our [Github Repository](https://github.com/friendica/docker) and write an issue.
