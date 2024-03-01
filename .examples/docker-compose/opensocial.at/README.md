# Opensocial.at setup

This example of the current opensocial.at configuration has to be seen as a possible "production-ready" environment.
The focus of this configuration is on performance and scalability.

## Prerequisites

This setup needs some configuration first to be fully usable.

1. It uses an external, dedicated database, which is not included here (you can just add a `mariadb` service directly)
2. avatar caching needs to be enabled
   1. Enable the system-config `system.avatar_cache`
   2. Set `avatar_cache_path` to `/var/www/avatar`
3. It uses a traefik docker service as overall reverse proxy for the whole docker environment
   1. Otherwise, adaptations of the two services `web` and `avatar` are necessary 

## The setup

The setup splits Friendica in as much (micro)services as possible.

### Split Frontend & Daemon

This setup splits the frontend services from the background Daemon.
So it's possible to scale different aspect from the frontend without harming states of the cronjob forks of the Daemon.  

### Redis

Redis is a highly optimized, in-memory key-value storage.

The current setup uses redis for two use-cases:
- Redis as PHP overall session handler  
- Redis for Friendica specific session-state handling

### [app](./app) (php-fpm)

The frontend logic of each user-request is computed by a php-fpm instance.
Because of the distributed session handling, it's possible to scale as much php-fpm app-instances as you need.

### [web](./web) (nginx)

This nginx instance is a reverse proxy for the frontend logic to avoid direct access to the php-fpm.
And it delivers static resources directly without passing the request to the php-fpm instance.

### [avatar](./avatar) (nginx)

This stateless nginx instance delivers all avatar-pictures of this instance.

### [cron](./app) (php-fpm)

The background daemon, which is based on the same image as the app-image.
