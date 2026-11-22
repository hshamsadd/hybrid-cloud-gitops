#!/bin/sh
set -eu

cd /var/www/wallabag

: "${SYMFONY__ENV__DATABASE_HOST:?Database host required}"
: "${SYMFONY__ENV__DATABASE_USER:?Database user required}"
: "${SYMFONY__ENV__DATABASE_PASSWORD:?Database password required}"

# Generate the configuration from Vault-backed environment variables.
envsubst \
  < /etc/wallabag/parameters.template.yml \
  > app/config/parameters.yml

# No automatic database creation, migrations or Composer installation.
exec s6-svscan /etc/s6/
