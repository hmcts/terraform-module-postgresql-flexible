#!/usr/bin/env bash
set -x # enable debug mode
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

# Get DB & auth info
SINGLE_SERVER_USER=$(az keyvault secret show --vault-name "${KV_NAME}" --name "${USER_SECRET_NAME}" --subscription "${KV_SUBSCRIPTION}" --query value -o tsv)
SINGLE_SERVER_PASS=$(az keyvault secret show --vault-name "${KV_NAME}" --name "${PASS_SECRET_NAME}" --subscription "${KV_SUBSCRIPTION}" --query value -o tsv)
if [[ $SINGLE_SERVER_USER == *'@'* ]]; then
   SINGLE_SERVER_USER="${SINGLE_SERVER_USER%%@*}"
fi

export PGUSER="${SINGLE_SERVER_USER}"
export PGPASSWORD="${SINGLE_SERVER_PASS}"
export PGDATABASE="${DB_NAME}"

echo 'Report Tables: ' $REPORT_PRIVILEGE_TABLES
IFS=' ' read -r -a TABLES <<< "$REPORT_PRIVILEGE_TABLES"
echo 'TABLES: ' "${TABLES[@]}"
# Loop through tables object per DB/Schema
for table in "${TABLES[@]}"; do
   SQL_COMMAND="GRANT SELECT ON TABLE \"$REPORT_PRIVILEGE_SCHEMA\".\"$table\" TO \"$REPORT_GROUP\";"
   psql -c "${SQL_COMMAND}"
done
set +x # disable debug mode
