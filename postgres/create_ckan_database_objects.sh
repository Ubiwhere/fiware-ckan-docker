#!/bin/bash

export PGUSER=postgres

abort () {
  echo "$@" >&2
  exit 1
}

if [ -z "$CKAN_SQLALCHEMY_URL" ]; then
  abort "Please provide a CKAN_SQLALCHEMY_URL env var"
fi

IFS='/' read -ra CONN_DETAILS_1 <<< "$CKAN_SQLALCHEMY_URL"
IFS='@' read -ra CONN_DETAILS_2 <<< "${CONN_DETAILS_1[2]}"
IFS=':' read -ra CONN_DETAILS_3 <<< "${CONN_DETAILS_2[0]}"
CKAN_DB_NAME="${CONN_DETAILS_1[3]}"
CKAN_DB_USER="${CONN_DETAILS_3[0]}"
CKAN_DB_USER_PASS="${CONN_DETAILS_3[1]}"


echo "******CREATING CKAN ROLE******"
psql <<- EOSQL
   CREATE ROLE $CKAN_DB_USER WITH LOGIN PASSWORD '${CKAN_DB_USER_PASS}' NOSUPERUSER NOCREATEDB NOCREATEROLE;
EOSQL

echo "******CREATING CKAN DATABASE******"
psql <<- EOSQL
   CREATE DATABASE $CKAN_DB_NAME WITH OWNER $CKAN_DB_USER;
EOSQL


if [ -n "$CKAN_DATASTORE_WRITE_URL" ]; then

    IFS='/' read -ra CONN_DETAILS_1 <<< "$CKAN_DATASTORE_WRITE_URL"
    IFS='@' read -ra CONN_DETAILS_2 <<< "${CONN_DETAILS_1[2]}"
    IFS=':' read -ra CONN_DETAILS_3 <<< "${CONN_DETAILS_2[0]}"
    CKAN_DATASTORE_DB_NAME="${CONN_DETAILS_1[3]}"
    CKAN_DATASTORE_RW_DB_USER="${CONN_DETAILS_3[0]}"
    CKAN_DATASTORE_RW_DB_USER_PASS="${CONN_DETAILS_3[1]}"

    IFS='/' read -ra CONN_DETAILS_1 <<< "$CKAN_DATASTORE_READ_URL"
    IFS='@' read -ra CONN_DETAILS_2 <<< "${CONN_DETAILS_1[2]}"
    IFS=':' read -ra CONN_DETAILS_3 <<< "${CONN_DETAILS_2[0]}"
    CKAN_DATASTORE_RO_DB_USER="${CONN_DETAILS_3[0]}"
    CKAN_DATASTORE_RO_DB_USER_PASS="${CONN_DETAILS_3[1]}"

    echo "******CREATING CKAN DATASTORE ROLES******"

    if [ "$CKAN_DATASTORE_RW_DB_USER" != "$CKAN_DB_USER" ]; then
        psql <<- EOSQL
        CREATE ROLE $CKAN_DATASTORE_RW_DB_USER WITH LOGIN PASSWORD '${CKAN_DATASTORE_RW_DB_USER_PASS}' NOSUPERUSER NOCREATEDB NOCREATEROLE;
EOSQL
    fi
    psql <<- EOSQL
   CREATE ROLE $CKAN_DATASTORE_RO_DB_USER WITH LOGIN PASSWORD '${CKAN_DATASTORE_RO_DB_USER_PASS}' NOSUPERUSER NOCREATEDB NOCREATEROLE;
EOSQL

    echo "******CREATING CKAN DATASTORE DATABASE******"
    psql <<- EOSQL
   CREATE DATABASE $CKAN_DATASTORE_DB_NAME WITH OWNER $CKAN_DATASTORE_RW_DB_USER;
EOSQL

    echo "******SETTING CKAN DATASTORE DATABASE PERMISSIONS******"
    psql -d $CKAN_DATASTORE_DB_NAME <<- EOSQL
   REVOKE CREATE ON SCHEMA public FROM PUBLIC;
   REVOKE USAGE ON SCHEMA public FROM PUBLIC;
   GRANT CREATE ON SCHEMA public TO $CKAN_DB_USER;
   GRANT USAGE ON SCHEMA public TO $CKAN_DB_USER;
   GRANT CREATE ON SCHEMA public TO $CKAN_DATASTORE_RW_DB_USER;
   GRANT USAGE ON SCHEMA public TO $CKAN_DATASTORE_RW_DB_USER;
   REVOKE CONNECT ON DATABASE $CKAN_DB_NAME FROM $CKAN_DATASTORE_RO_DB_USER;
   GRANT CONNECT ON DATABASE $CKAN_DATASTORE_DB_NAME TO $CKAN_DATASTORE_RO_DB_USER;
   GRANT USAGE ON SCHEMA public TO $CKAN_DATASTORE_RO_DB_USER;
   GRANT SELECT ON ALL TABLES IN SCHEMA public TO $CKAN_DATASTORE_RO_DB_USER;
   ALTER DEFAULT PRIVILEGES FOR USER $CKAN_DATASTORE_RW_DB_USER IN SCHEMA public
   GRANT SELECT ON TABLES TO $CKAN_DATASTORE_RO_DB_USER;
   CREATE OR REPLACE VIEW "_table_metadata" AS
    SELECT DISTINCT
        substr(md5(dependee.relname || COALESCE(dependent.relname, '')), 0, 17) AS "_id",
        dependee.relname AS name,
        dependee.oid AS oid,
        dependent.relname AS alias_of
        -- dependent.oid AS oid
    FROM
        pg_class AS dependee
        LEFT OUTER JOIN pg_rewrite AS r ON r.ev_class = dependee.oid
        LEFT OUTER JOIN pg_depend AS d ON d.objid = r.oid
        LEFT OUTER JOIN pg_class AS dependent ON d.refobjid = dependent.oid
    WHERE
        (dependee.oid != dependent.oid OR dependent.oid IS NULL) AND
        (dependee.relname IN (SELECT tablename FROM pg_catalog.pg_tables)
            OR dependee.relname IN (SELECT viewname FROM pg_catalog.pg_views)) AND
        dependee.relnamespace = (SELECT oid FROM pg_namespace WHERE nspname='public')
    ORDER BY dependee.oid DESC;
    ALTER VIEW "_table_metadata" OWNER TO $CKAN_DB_USER;
    GRANT SELECT ON "_table_metadata" TO $CKAN_DATASTORE_RO_DB_USER;
EOSQL
fi

echo ""
echo "******CKAN DATABASE OBJECTS CREATED******"



