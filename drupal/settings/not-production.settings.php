<?php

/**
 * @file
 * Non-production settings. Included from settings.php (all.settings.php for now).
 */

// See comment in all.settings.php.
// phpcs:ignore DrupalPractice.CodeAnalysis.VariableAnalysis.UndefinedVariable
$govcms_includes = isset($govcms_includes) ? $govcms_includes : __DIR__;

/**
 * Show all error messages, with backtrace information.
 *
 * In case the error level could not be fetched from the database, as for
 * example the database connection failed, we rely only on this value.
 */
$config['system.logging']['error_level'] = 'verbose';

/**
 * Disable Google Analytics from sending dev GA data.
 */
$config['google_analytics.settings']['account'] = 'UA-XXXXXXXX-YY';

/**
 * Disable Akamai purging.
 */
$config['akamai.settings']['disabled'] = TRUE;

/**
 * Set dummy Key values in place of missing env variables.
 */
$config['key.key.akamai_access_token']['key_provider'] = 'config';
$config['key.key.akamai_access_token']['key_provider_settings']['key_value'] = '1';
$config['key.key.akamai_client_token']['key_provider'] = 'config';
$config['key.key.akamai_client_token']['key_provider_settings']['key_value'] = '1';
$config['key.key.akamai_client_secret']['key_provider'] = 'config';
$config['key.key.akamai_client_secret']['key_provider_settings']['key_value'] = '1';

// Stage file proxy.
if (getenv('STAGE_FILE_PROXY_URL')) {
  $config['stage_file_proxy.settings']['origin'] = getenv('STAGE_FILE_PROXY_URL');
}
elseif (getenv('LAGOON_PROJECT')) {
  $config['stage_file_proxy.settings']['origin'] = 'https://nginx-' . getenv('LAGOON_PROJECT') . '-master.govcms.amazee.io';
}
