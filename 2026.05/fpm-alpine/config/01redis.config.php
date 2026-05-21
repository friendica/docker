<?php

if (getenv('REDIS_HOST')) {
	return [
		'system' => [
			'session_handler' => 'cache',
			'distributed_cache_driver' => 'redis',
			'lock_driver' => 'redis',
			'redis_host' => getenv('REDIS_HOST'),
			'redis_port' => (getenv('REDIS_PORT') ?: ''),
			'redis_password' => (getenv('REDIS_PW') ?: ''),
			'redis_db' => (getenv('REDIS_DB') ?: 0),
		],
	];
} else {
	return [];
}
