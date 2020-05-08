#!/usr/bin/env bats

load ../_helpers_govcms

setup() {
  if [ ! -f "/tmp/bats/settings.php" ]; then
    mkdir -p /tmp/bats
    (cd /tmp/bats && curl -O https://raw.githubusercontent.com/simesy/govcms8-scaffold/paas-saas-mash-up/web/sites/default/settings.php)
  fi
}

settings() {
  JSON=$(./tests/drupal-settings-to-json.php)
  echo "$JSON"
}

@test "Shield settings allows CLI" {
  OUT=$(settings | jq -cr '.config | "\(.["shield.settings"]["allow_cli"])"')
  [ "$OUT" == "true" ]
}

@test "File path is correct" {
  OUT=$(settings | jq -cr .settings.file_public_path)
  [ "$OUT" == "sites/default/files" ]
}

@test "Private file path is correct" {
  OUT=$(settings | jq -cr .settings.file_private_path)
  [ "$OUT" == "sites/default/files/private" ]
}

@test "Tmp file path is correct" {
  OUT=$(settings | jq -cr .settings.file_temporary_path)
  [ "$OUT" == "sites/default/files/private/tmp" ]
}

#@test "Ensure GovCMS 404 class" {
#  @see @todo in all.settings.php
#}

@test "GA disabled for dev" {
  DEV1=$(
    LAGOON_ENVIRONMENT_TYPE=development \
    settings | jq -rc '.config | "\(.["google_analytics.settings"])"'
  )
  DEV2=$(
    DEV_MODE=true \
    settings | jq -rc '.config | "\(.["google_analytics.settings"])"'
  )
  [ "$(echo "$DEV1" | jq -rc .account)" == "UA-XXXXXXXX-YY" ]
  [ "$(echo "$DEV2" | jq -rc .account)" == "UA-XXXXXXXX-YY" ]
}

@test "GA settings for prod" {
  SNIPPET=$(
    LAGOON_ENVIRONMENT_TYPE=production \
    settings | jq -rc '.config | "\(.["google_analytics.settings"]["codesnippet"]["after"])"'
  )
  [[ "$SNIPPET" == *"gtag('config', 'UA-54970022-1', {'name': 'govcms'})"* ]]
  [[ "$SNIPPET" == *"gtag('govcms.send', 'pageview', {'anonymizeIp': true})"* ]]
}

@test "Stage file proxy settings for prod" {
  SFP=$(
    LAGOON_ENVIRONMENT_TYPE=production \
    settings | jq -rc '.config | "\(.["stage_file_proxy.settings"])"'
  )
  [ "$(echo "$SFP" | jq -rc .origin)" == "false" ]
}

@test "Stage file proxy settings for dev" {
  SFP_DEFAULT=$(
    LAGOON_PROJECT=govcmsd8 \
    LAGOON_ENVIRONMENT_TYPE=development \
    settings | jq -rc '.config | "\(.["stage_file_proxy.settings"])"'
  )
  SFP_OVERRIDE=$(
    LAGOON_PROJECT=should-not-use \
    STAGE_FILE_PROXY_URL="https://www.govcms.gov.au" \
    LAGOON_ENVIRONMENT_TYPE=development \
    settings | jq -rc '.config | "\(.["stage_file_proxy.settings"])"'
  )

  [ "$(echo "$SFP_DEFAULT" | jq -rc .origin)" == "https://nginx-govcmsd8-master.govcms.amazee.io" ]
  [ "$(echo "$SFP_OVERRIDE" | jq -rc .origin)" == "https://www.govcms.gov.au" ]
}

@test "Solr settings" {
  SOLR=$(
    SOLR_HOST=labradoodle \
    SOLR_CORE=endor \
    LAGOON=true \
    settings | jq -rc '.config | "\(.["search_api.server"])"'
  )
  [ "$(echo "$SOLR" | jq -rc .backend_config.connector_config.host)" == "labradoodle" ]
  [ "$(echo "$SOLR" | jq -rc .backend_config.connector_config.path)" == '/solr/endor' ]
}

@test "Database settings are expected" {
  DB=$(
    LAGOON=true \
    MARIADB_DATABASE=dbname1 \
    MARIADB_USERNAME=dbusername1 \
    MARIADB_PASSWORD=dbpassword1 \
    MARIADB_HOST=dbreplicahost1 \
    settings | jq -rc '.databases.default.default'
  )

  [ "$(echo "$DB" | jq -rc .driver)" == "mysql" ]
  [ "$(echo "$DB" | jq -rc .database)" == "dbname1" ]
  [ "$(echo "$DB" | jq -rc .username)" == "dbusername1" ]
  [ "$(echo "$DB" | jq -rc .password)" == "dbpassword1" ]
  [ "$(echo "$DB" | jq -rc .host)" == "dbreplicahost1" ]
  [ "$(echo "$DB" | jq -rc .port)" == "3306" ]
  [ "$(echo "$DB" | jq -rc .charset)" == "utf8mb4" ]
  [ "$(echo "$DB" | jq -rc .collation)" == "utf8mb4_general_ci" ]
}

@test "Database settings with replica enabled" {
  DB=$(
    LAGOON=true \
    MARIADB_DATABASE=dbname1 \
    MARIADB_USERNAME=dbusername1 \
    MARIADB_PASSWORD=dbpassword1 \
    MARIADB_HOST=dbreplicahost1 \
    MARIADB_READREPLICA_HOSTS="dbreplicahost1 dbreplicahost2" \
    settings | jq -rc '.databases'
  )

  [ "$(echo "$DB" | jq -rc .default.default.driver)" == "mysql" ]
  [ "$(echo "$DB" | jq -rc .default.default.database)" == "dbname1" ]
  [ "$(echo "$DB" | jq -rc .default.default.username)" == "dbusername1" ]
  [ "$(echo "$DB" | jq -rc .default.default.password)" == "dbpassword1" ]
  [ "$(echo "$DB" | jq -rc .default.default.host)" == "dbreplicahost1" ]
  [ "$(echo "$DB" | jq -rc .default.default.port)" == "3306" ]
  [ "$(echo "$DB" | jq -rc .default.default.charset)" == "utf8mb4" ]
  [ "$(echo "$DB" | jq -rc .default.default.collation)" == "utf8mb4_general_ci" ]

  # Standalone connection to the read replica.
  [ "$(echo "$DB" | jq -rc .read.default.driver)" == "mysql" ]
  [ "$(echo "$DB" | jq -rc .read.default.database)" == "dbname1" ]
  [ "$(echo "$DB" | jq -rc .read.default.username)" == "dbusername1" ]
  [ "$(echo "$DB" | jq -rc .read.default.password)" == "dbpassword1" ]
  [ "$(echo "$DB" | jq -rc .read.default.host)" == "dbreplicahost1" ]
  [ "$(echo "$DB" | jq -rc .read.default.port)" == "3306" ]
  [ "$(echo "$DB" | jq -rc .read.default.charset)" == "utf8mb4" ]
  [ "$(echo "$DB" | jq -rc .read.default.collation)" == "utf8mb4_general_ci" ]

  # Replica support to the default database connection (2 replica hosts).
  [ "$(echo "$DB" | jq -rc .default.replica[0].driver)" == "mysql" ]
  [ "$(echo "$DB" | jq -rc .default.replica[0].database)" == "dbname1" ]
  [ "$(echo "$DB" | jq -rc .default.replica[0].username)" == "dbusername1" ]
  [ "$(echo "$DB" | jq -rc .default.replica[0].password)" == "dbpassword1" ]
  [ "$(echo "$DB" | jq -rc .default.replica[0].host)" == "dbreplicahost1" ]
  [ "$(echo "$DB" | jq -rc .default.replica[0].port)" == "3306" ]
  [ "$(echo "$DB" | jq -rc .default.replica[0].charset)" == "utf8mb4" ]
  [ "$(echo "$DB" | jq -rc .default.replica[0].collation)" == "utf8mb4_general_ci" ]

  [ "$(echo "$DB" | jq -rc .default.replica[1].driver)" == "mysql" ]
  [ "$(echo "$DB" | jq -rc .default.replica[1].database)" == "dbname1" ]
  [ "$(echo "$DB" | jq -rc .default.replica[1].username)" == "dbusername1" ]
  [ "$(echo "$DB" | jq -rc .default.replica[1].password)" == "dbpassword1" ]
  [ "$(echo "$DB" | jq -rc .default.replica[1].host)" == "dbreplicahost2" ]
  [ "$(echo "$DB" | jq -rc .default.replica[1].port)" == "3306" ]
  [ "$(echo "$DB" | jq -rc .default.replica[1].charset)" == "utf8mb4" ]
  [ "$(echo "$DB" | jq -rc .default.replica[1].collation)" == "utf8mb4_general_ci" ]
}
