#!/bin/bash

set -eu

# Initialize CKAN if it hasn't already been done
if [ ! -e "${CKAN_CONFIG}/.ckan_initialized" ]; then
  
  paster --plugin=ckan db init -c "${CKAN_CONFIG}/production.ini"

  # Create a default sysadmin user
  if [ ${CKAN_SYSADMIN} = "true" ]; then
    /usr/bin/expect << EOF | tee -a /etc/ckan/default/.ckan_sysadmin
      set timeout 2
      spawn paster --plugin=ckan sysadmin -c ${CKAN_CONFIG}/production.ini add ${CKAN_ADMIN} email=${CKAN_ADMIN_EMAIL}
      expect "Create new user.*"
      send -- "y\r"
      expect "password.*"
      send -- "${CKAN_ADMIN_PASSWORD}\r"
      expect "Confirm password.*"
      send -- "${CKAN_ADMIN_PASSWORD}\r"
      expect eof
EOF
  fi

  # Create check file to avoid future initialization
  touch "${CKAN_CONFIG}/.ckan_initialized"
fi

exec "$@"