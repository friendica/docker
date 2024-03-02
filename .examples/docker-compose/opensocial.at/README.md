# Opensocial.at setup

This configuration running at https://opensocial.at is an example of "production-ready" environment.
It focuses on performance and scalability.

## Prerequisites

This setup needs some configuration first to be usable as-is.

1. It uses an external, dedicated database, which is not included here (you can just add a `mariadb` service directly).
2. Avatar caching needs to be enabled
   1. Enable the system-config `system.avatar_cache`.
   2. Set `avatar_cache_path` to `/var/www/avatar`.
3. It uses a Traefik Docker service as overall reverse proxy for the whole Docker environment.
   1. Otherwise, adaptations of the two services `web` and `avatar` are necessary.

## The setup

The setup splits Friendica in as many services as possible.

### Split Frontend & Daemon

This setup splits the frontend services from the background daemon so that it's possible to scale the different aspects of the frontend without harming the state of the cronjob forks of the daemon.  

### Redis

Redis is a highly optimized, in-memory key-value storage.

The current setup uses Redis for two features:
- PHP native session handling.
- Friendica-specific session handling.

### [app](./app) (php-fpm)

Each incoming HTTP request is processed by a php-fpm instance.
Thanks to the distributed session handling, it's possible to spawn as many `app` instances as you need.

### [web](./web) (nginx)

This nginx instance is a reverse proxy for incoming HTTP requests.
It serves static resources directly and passes the script requests to the php-fpm instance.

### [avatar](./avatar) (nginx)

This stateless nginx instance serves all avatar pictures of this Friendica node.

### [cron](./app) (php-fpm)

The background daemon, which is based on the same image as the app-image.
