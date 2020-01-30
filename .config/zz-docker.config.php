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

if (getenv('FRIENDICA_TZ')) {
	$config['config']['timezone'] = getenv('FRIENDICA_TZ');
}

if (getenv('FRIENDICA_LANG')) {
	$config['config']['language'] = getenv('FRIENDICA_LANG');
}

if (getenv('FRIENDICA_ADMIN_MAIL')) {
	$config['config']['admin_email'] = getenv('FRIENDICA_ADMIN_MAIL');
}

if (getenv('FRIENDICA_SITENAME')) {
	$config['config']['sitename'] = getenv('FRIENDICA_SITENAME');
}

if (!empty(getenv('FRIENDICA_NO_VALIDATION'))) {
	$config['system']['disable_url_validation'] = true;
	$config['system']['disable_email_validation'] = true;
}

if (!empty(getenv('FRIENDICA_DATA'))) {
	$config['storage']['class'] = \Friendica\Model\Storage\Filesystem::class;

	if (!empty(getenv('FRIENDICA_DATA_DIR'))) {
		$config['storage']['filesystem_path'] = getenv('FRIENDICA_DATA');
	}
}

if (!empty(getenv('FRIENDICA_DEBUGGING'))) {
	$config['system']['debugging'] = true;
	if (!empty(getenv('FRIENDICA_LOGFILE'))) {
		$config['system']['logfile'] = getenv('FRIENDICA_LOGFILE');
	}
	if (!empty(getenv('FRIENDICA_LOGLEVEL'))) {
		$config['system']['loglevel'] = getenv('FRIENDICA_LOGLEVEL');
	}
}

if (!empty(getenv('HOSTNAME'))) {
	$config['config']['hostname'] = getenv('HOSTNAME');
}

return $config;
