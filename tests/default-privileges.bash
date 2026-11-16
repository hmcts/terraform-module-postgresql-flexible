#!/usr/bin/env bash
# Run with PostgreSQL's initdb, pg_ctl and psql on PATH. No Azure resources are used.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
TEST_DIR=$(mktemp -d)
cleanup() {
   pg_ctl -D "$TEST_DIR/data" -m immediate stop >/dev/null 2>&1 || true
   rm -rf "$TEST_DIR"
}
trap cleanup EXIT
initdb -D "$TEST_DIR/data" -A trust -U bootstrap >/dev/null
# Unix socket only; isolate the test from any running database.
pg_ctl -D "$TEST_DIR/data" -l "$TEST_DIR/server.log" \
   -o "-c listen_addresses='' -k '$TEST_DIR'" -w start >/dev/null
export PGHOST="$TEST_DIR" PGPORT=5432 PGDATABASE=postgres PGUSER=bootstrap
export PGOPTIONS='-c exit_on_error=on'
psql -X -v ON_ERROR_STOP=1 <<'SQL'
CREATE ROLE pgadmin LOGIN;
CREATE ROLE jenkins LOGIN;
GRANT pgadmin TO jenkins;
CREATE ROLE "DB Reader";
CREATE ROLE "DB Writer";
CREATE DATABASE application OWNER pgadmin;
SQL
export PGDATABASE=application
psql -X -v ON_ERROR_STOP=1 <<'SQL'
SET ROLE pgadmin;
CREATE SCHEMA draft;
CREATE SCHEMA ccd;
CREATE TABLE draft.existing (id integer);
SQL

export DB_NAME=application DB_ADMIN=pgadmin DB_USER=jenkins
export DB_READER_USER='DB Reader' DB_WRITER_USER='DB Writer'
export ENABLE_READ_ONLY_GROUP_ACCESS=true ENABLE_WRITE_GROUP_ACCESS=true
export DB_READER_SCHEMAS=public,draft,ccd DB_WRITER_SCHEMAS=public,draft,ccd
# Exercise the real schema-grant phase without running Azure authentication.
sed -n '/^SCHEMA_SQL=""/,$p' "$ROOT/set-postgres-permissions.bash" > "$TEST_DIR/schema-grants.bash"
source "$TEST_DIR/schema-grants.bash"

export PGUSER=bootstrap
psql -X -v ON_ERROR_STOP=1 <<'SQL'
DO $$
DECLARE
   creator text;
   namespace text;
   relation_name text;
BEGIN
   IF NOT has_table_privilege('DB Reader', 'draft.existing', 'SELECT') THEN
      RAISE EXCEPTION 'Reader cannot read existing table';
   END IF;
   FOREACH creator IN ARRAY ARRAY['pgadmin', 'jenkins'] LOOP
      EXECUTE format('SET LOCAL ROLE %I', creator);
      FOREACH namespace IN ARRAY ARRAY['public', 'draft', 'ccd'] LOOP
         relation_name := format('%I.%I', namespace, creator || '_future');
         EXECUTE format('CREATE TABLE %s (id serial PRIMARY KEY, value text)', relation_name);
         IF NOT has_table_privilege('DB Reader', relation_name, 'SELECT') THEN
            RAISE EXCEPTION 'Reader cannot read %', relation_name;
         END IF;
         IF has_table_privilege('DB Reader', relation_name, 'INSERT') THEN
            RAISE EXCEPTION 'Reader can write %', relation_name;
         END IF;
         EXECUTE 'SET LOCAL ROLE "DB Reader"';
         EXECUTE format('SELECT * FROM %s', relation_name);
         EXECUTE 'SET LOCAL ROLE "DB Writer"';
         EXECUTE format('INSERT INTO %s (value) VALUES (''test'')', relation_name);
         EXECUTE format('UPDATE %s SET value = ''updated''', relation_name);
         EXECUTE format('DELETE FROM %s', relation_name);
         EXECUTE format('SET LOCAL ROLE %I', creator);
      END LOOP;
      RESET ROLE;
   END LOOP;
END $$;
SQL
printf 'Default privileges passed for existing tables and future tables from both creators.\n'
