<?php

/**
 * Fallback config to make it possible overwriting config values
 * because of docker environment variables
 *
 * This doesn't affect DB configurations, but will replace other config values
 */

$config = [
	'system' => [
		// Necessary because otherwise the daemon isn't working
		'pidfile' => '/var/run/friendica.pid',

		'logfile' => '/var/www/html/friendica.log',
		'loglevel' => 'notice',
	],
	'storage' => [
		'filesystem_path' => '/var/www/html/storage',
	],
];

if (!empty(getenv('FRIENDICA_NO_VALIDATION'))) {
	$config['system']['disable_url_validation'] = true;
	$config['system']['disable_email_validation'] = true;
}

if (!empty(getenv('SMTP_DOMAIN'))) {
	$smtp_from = !empty(getenv('SMTP_FROM')) ? getenv('SMTP_FROM') : 'no-reply';

	$config['config']['sender_email'] = $smtp_from . "@" . getenv('SMTP_DOMAIN');
}

return $config;
