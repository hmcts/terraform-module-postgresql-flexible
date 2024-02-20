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

SINGLE_SERVER_USER=$(az keyvault secret show --vault-name "${KV_NAME}" --name "${USER_SECRET_NAME}" --subscription "${KV_SUBSCRIPTION}" --query value -o tsv)
SINGLE_SERVER_PASS=$(az keyvault secret show --vault-name "${KV_NAME}" --name "${PASS_SECRET_NAME}" --subscription "${KV_SUBSCRIPTION}" --query value -o tsv)

if [[ $SINGLE_SERVER_USER == *'@'* ]]; then
   SINGLE_SERVER_USER="${SINGLE_SERVER_USER%%@*}"
fi

SQL_COMMAND="
GRANT ${DB_ADMIN} to ${SINGLE_SERVER_USER};
REASSIGN OWNED BY ${SINGLE_SERVER_USER} TO ${DB_ADMIN};
REVOKE ${DB_ADMIN} FROM ${SINGLE_SERVER_USER};
GRANT ${SINGLE_SERVER_USER} TO ${DB_ADMIN};
"

set -x
export PGDATABASE="${DB_NAME}"
export PGUSER="${SINGLE_SERVER_USER}"
export PGPASSWORD=$SINGLE_SERVER_PASS_VAL
psql -c "${SQL_COMMAND}"
set +x
