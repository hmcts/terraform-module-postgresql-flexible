#!/usr/bin/env bash

export PGPORT=5432
export AZURE_CONFIG_DIR=~/.azure-db-manager
az login --identity

## Delay until DB DNS and propagated
COUNT=0;
MAX=10;
while true; do
   ping -c 1 $DB_HOST_NAME &>/dev/null
   if [[ $? -eq 0 ]]; then
      break
   fi
   if [[ $COUNT -eq $MAX ]]; then
      break
   else
      COUNT=$[$COUNT+1]
   fi
   sleep 5
done

export PGPASSWORD=$DB_PASSWORD

JENKINS_SQL_COMMAND="
GRANT ALL ON ALL TABLES IN SCHEMA public TO \"${DB_USER}\";
GRANT ${DB_ADMIN} to \"${DB_USER}\";
GRANT ${DB_ADMIN} to \"${DB_ADMIN_GROUP}\";
"

set -x
export PGDATABASE="${DB_NAME}"
export PGUSER="${DB_ADMIN}"
psql -c "${JENKINS_SQL_COMMAND}"
set +x

export PGPASSWORD=$(az account get-access-token --resource-type oss-rdbms --query accessToken -o tsv)

SQL_COMMAND_POSTGRES="
DO
\$do\$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles  -- SELECT list can be empty for this
      WHERE rolname = '${DB_READER_USER}') THEN

      PERFORM pgaadauth_create_principal('${DB_READER_USER}', false, false);

   END IF;
END
\$do\$;
"

set -x
export PGDATABASE="postgres"
export PGUSER="${DB_USER}"
psql -c "${SQL_COMMAND_POSTGRES}"
set +x

SQL_COMMAND="

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO PUBLIC;
REVOKE CREATE ON SCHEMA public FROM public;
GRANT USAGE ON SCHEMA public TO \"${DB_READER_USER}\";
GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"${DB_READER_USER}\";

"
set -x
export PGDATABASE="${DB_NAME}"
export PGUSER="${DB_USER}"
psql -c "${SQL_COMMAND}"
set +x

REMOVE_GROUP_COMMAND="
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM \"DTS Platform Operations\";
DROP ROLE IF EXISTS \"DTS Platform Operations\";
"

echo "Removing group 'DTS Platform Operations' from database '${DB_NAME}'..."
set -x
psql -h "$DB_HOST_NAME" -U "$DB_ADMIN" -d "$DB_NAME" -c "${REMOVE_GROUP_COMMAND}"
set +x
