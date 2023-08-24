#!/usr/bin/env bash

export AZURE_CONFIG_DIR=~/.azure-db-manager
az login --identity

# shellcheck disable=SC2155

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

echo "Setting user DB User permissions with:"
echo "${DB_NAME}"
echo "${DB_READER_SCHEMA_NAME}"

JENKINS_SQL_COMMAND="
GRANT ALL ON ALL TABLES IN SCHEMA public TO \"${DB_USER}\";
"

psql "sslmode=require host=${DB_HOST_NAME} port=5432 dbname=${DB_NAME} user=${DB_ADMIN}" -c "${JENKINS_SQL_COMMAND}"

export PGPASSWORD=$(az account get-access-token --resource-type oss-rdbms --query accessToken -o tsv)

psql "sslmode=require host=${DB_HOST_NAME} port=5432 dbname=postgres user=${DB_USER}" -c "${SQL_COMMAND_POSTGRES}"

SQL_COMMAND="

ALTER DEFAULT PRIVILEGES IN SCHEMA \"${DB_READER_SCHEMA_NAME}\" GRANT SELECT ON TABLES TO \"${DB_READER_SCHEMA_NAME}\";
REVOKE CREATE ON SCHEMA \"${DB_READER_SCHEMA_NAME}\" FROM \"${DB_READER_SCHEMA_NAME}\";
GRANT USAGE ON SCHEMA \"${DB_READER_SCHEMA_NAME}\" TO \"${DB_READER_USER}\";
GRANT SELECT ON ALL TABLES IN SCHEMA \"${DB_READER_SCHEMA_NAME}\" TO \"${DB_READER_USER}\";

"

psql "sslmode=require host=${DB_HOST_NAME} port=5432 dbname=${DB_NAME} user=${DB_USER}" -c "${SQL_COMMAND}"

echo "DB script run complete."