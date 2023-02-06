#!/usr/bin/env bash



export AZURE_CONFIG_DIR=~/.azure-db-manager
az login --identity

# shellcheck disable=SC2155
export PGPASSWORD=$(az account get-access-token --resource-type oss-rdbms --query accessToken -o tsv)

##### this below SQL commands make sure that only service pricipal has CREATE databse rights
#### We have to do this becuase if the databse created by a Admin user, it can NOT be managed by any other Admin User

REMOVE_CREATE_COMMAND="
DO
\$do\$
		DECLARE 
    		role record;
		BEGIN 
    		FOR role IN select rolname from pg_catalog.pg_roles  where rolcreatedb=TRUE and rolsuper=FALSE and rolname<>'${DB_USER}'
            Loop
        		
                execute 'GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ' || quote_ident( role.rolname );
                
                execute 'grant usage on all sequences in schema public to ' || quote_ident( role.rolname );

                execute 'alter default privileges in schema public grant ALL PRIVILEGES on tables to ' || quote_ident( role.rolname );

                execute 'ALTER USER ' || quote_ident( role.rolname ) ||
                     ' WITH NOCREATEDB ' ;
                
    		END LOOP;
		END;
\$do\$
"

psql "sslmode=require host=${DB_HOST_NAME} port=5432 dbname=postgres user=${DB_USER}" -c "${REMOVE_CREATE_COMMAND}" 

	for row in $(echo "${DB_S}" | jq '.[].name | tostring'); do
                    DBNAME=`echo ${row} | sed 's/"//g'`
                    echo "this is DB ${DBNAME}" 
        psql "sslmode=require host=${DB_HOST_NAME} port=5432 dbname=${DBNAME} user=${DB_USER}" -c "${REMOVE_CREATE_COMMAND}" 				
	done