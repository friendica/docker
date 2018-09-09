<?php return <<<INI

[system]
cache_driver=redis
lock_driver=redis

redis_host=redis

pidfile = /var/run/friendica.pid

INI;
// Keep this line