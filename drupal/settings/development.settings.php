<?php

/**
 * @file
 * Non-production settings. Included from settings.php.
 */

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

/**
 * Configure stage file proxy.
 */
if (getenv('STAGE_FILE_PROXY_URL')) {
  $config['stage_file_proxy.settings']['origin'] = getenv('STAGE_FILE_PROXY_URL');
}
elseif (getenv('LAGOON_PROJECT')) {
  $config['stage_file_proxy.settings']['origin'] = 'https://nginx-master-' . getenv('LAGOON_PROJECT') . '.govcms6.amazee.io';
}

/**
 * Configure Environment indicator.
 */
$config['environment_indicator.indicator']['bg_color'] = '#006600';
$config['environment_indicator.indicator']['fg_color'] = '#FFFFFF';
$config['environment_indicator.indicator']['name'] = 'Non-production';

// Disable shield on development environment.
if (getenv('DISABLE_SHIELD') === 'true') {
  $config['shield.settings']['credentials']['shield']['user'] = NULL;
  $config['shield.settings']['credentials']['shield']['pass'] = NULL;
}