#!/usr/bin/env bash
set -euo pipefail

DB_HOST="${DB_HOST:-mysql}"
DB_PORT="${DB_PORT:-3306}"
DB_NAME="${DB_NAME:-openvk}"
DB_USER="${DB_USER:-ovkuser}"
DB_PASS="${DB_PASS:-changeme}"

echo "Waiting for MySQL at ${DB_HOST}:${DB_PORT} ..."
until mysqladmin ping -h"$DB_HOST" -P"$DB_PORT" --silent; do
  sleep 2
done
echo "MySQL is up."

# Generate config from template
envsubst < /opt/chandler/extensions/available/openvk/openvk.yml.template       > /opt/chandler/extensions/available/openvk/openvk.yml

# Initialize DB if empty
TABLES_COUNT=$(mysql -N -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS"       -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${DB_NAME}';")
if [ "$TABLES_COUNT" = "0" ]; then
  echo "Initializing database schema..."
  mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME"         < /opt/chandler/extensions/available/openvk/install/database.sql
  echo "DB schema imported."
else
  echo "DB already initialized (${TABLES_COUNT} tables)."
fi

# Start Chandler
exec php /opt/chandler/bin/chandler serve --host 0.0.0.0 --port 8080
