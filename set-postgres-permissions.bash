#!/usr/bin/env bash

export PGPORT=5432
export AZURE_CONFIG_DIR=~/.azure-db-manager
az login --identity

## Delay until DB DNS and propagated
COUNT=0;
MAX=10;
while true; do
   ping -c 1 $PGHOST &>/dev/null
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

SQL_COMMAND_POSTGRES=""

if [[ "${ENABLE_READ_ONLY_GROUP_ACCESS}" == "true" ]]; then
   SQL_COMMAND_POSTGRES+="
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
fi

if [[ "${ENABLE_WRITE_GROUP_ACCESS}" == "true" ]]; then
   SQL_COMMAND_POSTGRES+="
   DO
   \$do\$
   BEGIN
      IF NOT EXISTS (
         SELECT FROM pg_catalog.pg_roles  -- SELECT list can be empty for this
         WHERE rolname = '${DB_WRITER_USER}') THEN

         PERFORM pgaadauth_create_principal('${DB_WRITER_USER}', false, false);

      END IF;
   END
   \$do\$;
   "
fi

if [[ -n "${SQL_COMMAND_POSTGRES}" ]]; then
   set -x
   export PGDATABASE="postgres"
   export PGUSER="${DB_USER}"
   psql -c "${SQL_COMMAND_POSTGRES}"
   set +x
fi

SCHEMA_SQL=""

if [[ "${ENABLE_READ_ONLY_GROUP_ACCESS}" == "true" ]]; then
   SCHEMA_LIST=${DB_READER_SCHEMAS:-public}
   IFS=',' read -r -a READER_SCHEMAS <<< "$SCHEMA_LIST"

   for schema in "${READER_SCHEMAS[@]}"; do
      SCHEMA_SQL+="GRANT USAGE ON SCHEMA \"${schema}\" TO \"${DB_READER_USER}\";"
      SCHEMA_SQL+="GRANT SELECT ON ALL TABLES IN SCHEMA \"${schema}\" TO \"${DB_READER_USER}\";"
      SCHEMA_SQL+="ALTER DEFAULT PRIVILEGES IN SCHEMA \"${schema}\" GRANT SELECT ON TABLES TO \"${DB_READER_USER}\";"
   done
fi

if [[ "${ENABLE_WRITE_GROUP_ACCESS}" == "true" ]]; then
   SCHEMA_LIST=${DB_WRITER_SCHEMAS:-public}
   IFS=',' read -r -a WRITER_SCHEMAS <<< "$SCHEMA_LIST"

   for schema in "${WRITER_SCHEMAS[@]}"; do
      SCHEMA_SQL+="GRANT USAGE ON SCHEMA \"${schema}\" TO \"${DB_WRITER_USER}\";"
      SCHEMA_SQL+="GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA \"${schema}\" TO \"${DB_WRITER_USER}\";"
      SCHEMA_SQL+="GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA \"${schema}\" TO \"${DB_WRITER_USER}\";"
      SCHEMA_SQL+="ALTER DEFAULT PRIVILEGES IN SCHEMA \"${schema}\" GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO \"${DB_WRITER_USER}\";"
      SCHEMA_SQL+="ALTER DEFAULT PRIVILEGES IN SCHEMA \"${schema}\" GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO \"${DB_WRITER_USER}\";"
   done
fi

SQL_COMMAND="

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO PUBLIC;
REVOKE CREATE ON SCHEMA public FROM public;
${SCHEMA_SQL}

"

if [[ -n "${SCHEMA_SQL}" ]]; then
   set -x
   export PGDATABASE="${DB_NAME}"
   export PGUSER="${DB_USER}"
   psql -c "${SQL_COMMAND}"
   set +x
fi
