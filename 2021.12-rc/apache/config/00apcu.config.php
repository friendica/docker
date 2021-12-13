<?php

/**
 * If nothing else set, use APCu as a caching driver (best performance for local caching)
 */

return [
	'system' => [
		'cache_driver' => 'apcu',
	],
];
