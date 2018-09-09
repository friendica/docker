# Examples section

In this subfolder are some examples how to use the docker images.
There are two section:

* [`dockerfiles`](https://github.com/friendica/docker/tree/master/.examples/dockerfiles)
* [`docker-compose`](https://github.com/friendica/docker/tree/master/.examples/docker-compose)

The `dockerfiles` are derived images that add or alter certain functionalities of the default docker images.
In the `docker-compose` subfolder are examples for deployment of the application.

## Dockerfiles

The Dockerfiles use the default images as base image and build on top of it.

Examples | Descriptions
-------- | -------
[cron](https://github.com/friendica/docker/tree/master/.examples/dockerfiles/cron) | uses supervisor to run the cron job inside the container (so no extra container is needed).
[smtp](https://github.com/friendica/docker/tree/master/.examples/dockerfiles/smtp) | adds SMTP support to the Friendica container (necessary if you want to have mail support in Friendica).

### SMTP settings <a id="smtpsetting"></a>

The binary `ssmtp` is used for the `mail()` support of Friendica.

You have to set the `--hostname/-h` parameter correctly to use the right domainname for the `mail()` command.

You have to set a valid SMTP-MTA for the `SMTP` environment variable to enable mail support in Friendica.
A valid SMTP-MTA would be, for example, `mx.example.org`.

The following environment variables are possible for the SMTP examples.

-	`SITENAME` The name of the Friendica node. (**required** - Default: `Testsite`)
-	`SMTP` Address of the SMTP Mail-Gateway. (**required** - Default: `localhost`)
-	`SMTP_FROM` Sender user-part of the address. (Default: `no-reply` - e.g. no-reply@friendica.local)
-	`SMTP_AUTH_USER` Username for the SMTP Mail-Gateway. (Default: empty)
-	`SMTP_AUTH_PASS` Password for the SMTP Mail-Gateway. (Default: empty)
-	`SMTP_AUTH_METHOD` Authentication method for the SMTP Mail-Gateway. (Default: empty/plain text)

## docker-compose

In `docker-compose` additional services are bundled to create a complex Friendica installation.
The examples are designed to run out-of-the-box.

Before running the examples, you have to modify the `db.env` and `docker-compose.yml` file and fill in your custom information.

The docker-compose examples make heavily use of derived Dockerfiles to add configuration files into the containers.
This way they should also work on remote docker systems as _Docker for Windows_.
when running docker-compose on the same host as the docker daemon, another possibility would be to simply mount the files in the volumes section in the `docker-compose.yml` file.

### insecure

This examples should only be used for **testing** on the local network because it uses a unencrypted http connection.
When you want to have your server reachable from the internet adding HTTPS-encryption is mandatory!
For this use one of the [with-traefik-proxy](#with-traefik-proxy) examples.

To use this example complete the following steps:

1. choose a password for the database user in `db.env` behind `MYSQL_PASSWORD=`
2. run `docker-compose build --pull` to pull the mose recent base images and build the custom dockerfiles
3. start Friendica with `docker-compose up -d`

If you want to update your installation to a newer version, repeat 3 and 4.
**Note**: If you are on a develop branch (*-dev or *-rc) you have to update Friendica with the command `docker-compose exec app friendica update`

### with-traefik-proxy

The traefik proxy adds a proxy layer between Friendica and the internet.
The proxy is designed to server multiple sites on the same host machine.

The advantage in adding this layer is the ability to use [Let's Encrypt](https://letsencrypt.org/) out certification handling of the box.

Therefore you have to use adjust the `labels:` inside the `docker-compose.yml` to let traefik know what domains it should route and what certifications it should request.

To use this example complete the following steps:

1. open `docker-compose.yml`
   1. insert your friendica domain behind `hostname:`
   2. insert your friendica domain at `traefik.friendica.rule=Host:friendica.local`
2. choose a password for the database user in `db.env` behind `MYSQL_PASSWORD=`
3. open `proxy/traefik.toml`
   1. replace `domain = "example.org"` with your friendica domain
   2. replace `email = "root@example.org"` with a valid email
4. run `docker-compose build --pull` to pull the most recent base images and build the custom dockerfiles
5. start Friendica with `docker-compose up -d`

If you want to update your installation to a newer version, repeat 4 and 5.
**Note**: If you are on a develop branch (*-dev or *-rc) you have to update Friendica with the command `docker-compose exec app friendica update`