#!/usr/bin/env bash

template_properties_file="migration/migration-config-template.json"
properties_file="migration/migration-config.json"
single_server_admin_password=$(az keyvault secret show --vault-name "${single_server_kv_name}" --name "${single_server_secret_name}" --subscription "${kv_subscription}" --query value -o tsv)
flexible_server_admin_password=$(az keyvault secret show --vault-name "${flexible_server_kv_name}" --name "${flexible_server_secret_name}" --subscription "${kv_subscription}" --query value -o tsv)


# TODO check migration name doesn't exist

# Command to update json file
jq ". |
  .properties.OverwriteDBsInTarget = \"${overwrite_target_dbs}\" |
  .properties.SourceDBServerResourceId = \"${single_server_resource_id}\" |
  .properties.DBsToMigrate = ${dbs_to_migrate} |
  .properties.SecretParameters.AdminCredentials.SourceServerPassword = \"${single_server_admin_password}\" |
  .properties.SecretParameters.AdminCredentials.TargetServerPassword = \"${flexible_server_admin_password}\" " ${template_properties_file} > ${properties_file}


az postgres flexible-server migration create \
    --subscription "${subscription}" \
    --resource-group "${resource_group}"\
    --name "${flexible_server_name}" \
    --migration-name "${migration_name}" \
    --properties ${properties_file}

state=$(az postgres flexible-server migration show \
    --subscription "${subscription}" \
    --resource-group "${resource_group}"\
    --name "${flexible_server_name}" \
    --migration-name "${migration_name}" \
    --query ".properties.currentStatus.state")

echo "${state}"

