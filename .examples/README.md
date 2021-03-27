# Examples section

In this subfolder are some examples how to use the docker images.
There is currently one section:

* [`docker-compose`](https://github.com/friendica/docker/tree/stable/.examples/docker-compose)

In the `docker-compose` subfolder are examples for deployment of the application.

## docker-compose

In `docker-compose` additional services are bundled to create a complex Friendica installation.
The examples are designed to run out-of-the-box.

Before running the examples, you have to modify the `db.env` and `docker-compose.yml` file and fill in your custom information.

The docker-compose examples make heavily use of derived Dockerfiles to add configuration files into the containers.
This way they should also work on remote docker systems as _Docker for Windows_.
when running docker-compose on the same host as the docker daemon, another possibility would be to simply mount the files in the volumes section in the `docker-compose.yml` file.

### insecure

These examples should only be used for **testing** on the local network because they use an unencrypted http connection.
When you want to have your server reachable from the internet adding HTTPS-encryption is mandatory!
For this use one of the [with-traefik-proxy](#with-traefik-proxy) examples.

To use one of these examples, complete the following steps:

1. choose a password for the database user in `db.env` behind `MYSQL_PASSWORD=`
2. run `docker-compose build --pull` to pull the mose recent base images and build the custom dockerfiles
3. start Friendica with `docker-compose up -d`

If you want to update your installation to a newer version, repeat 3 and 4.
**Note**: If you are on a develop branch (*-dev or *-rc) you have to set the environment variable `FRIENDICA_UPGRADE=true` to update Friendica.

### with-traefik-proxy

The traefik proxy adds a proxy layer between Friendica and the internet.
The proxy is designed to server multiple sites on the same host machine.

The advantage in adding this layer is the ability to use [Let's Encrypt](https://letsencrypt.org/) out certification handling of the box.

Therefore you have to use adjust the `labels:` inside the `docker-compose.yml` to let traefik know what domains it should route and what certifications it should request.

To use this example complete the following steps:

1. open `docker-compose.yml`
   2. insert your friendica domain at `traefik.friendica.rule=Host:friendica.local`
2. choose a password for the database user in `db.env` behind `MYSQL_PASSWORD=`
3. open `proxy/traefik.toml`
   1. replace `domain = "example.org"` with your friendica domain
   2. replace `email = "root@example.org"` with a valid email
4. run `docker-compose build --pull` to pull the most recent base images and build the custom dockerfiles
5. start Friendica with `docker-compose up -d`

If you want to update your installation to a newer version, repeat 4 and 5.
**Note**: If you are on a develop branch (*-dev or *-rc) you have to set the environment variable `FRIENDICA_UPGRADE=true` to update Friendica.
