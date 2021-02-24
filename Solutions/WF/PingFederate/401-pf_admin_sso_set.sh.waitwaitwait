#!/bin/bash

# revert PingOne for PingFed Admin SSO

#Variables needed to be passed for this script:
# PINGFED_BASE_URL
# DOMAIN

CREATE_PF_ADMIN=$(curl -s --write-out "%{http_code}\n" --insecure --location --request POST "$PINGFED_BASE_URL:9999/pf-admin-api/v1/administrativeAccounts" \
--header 'Content-Type: application/json' \
--header 'X-XSRF-Header: pingfederate' \
--header 'Authorization: Basic QWRtaW5pc3RyYXRvcjoyRmVkZXJhdGVNMHJl' \
--data-raw '{
    "username": "PingFederateAdmin",
    "password": "2FederateM0re",
    "active": "true",
    "emailAddress": "'"pingfederateadmin@$DOMAIN"'",
    "description": "Used for PingOne Admin SSO",
    "roles": [
        "ADMINISTRATOR"
    ]
}')

CREATE_PF_ADMIN_RESULT=$(echo $CREATE_PF_ADMIN | sed 's@.*}@@')
if [ $CREATE_PF_ADMIN_RESULT == "200" ] ; then
    echo "Added PingFederateAdmin account..."
else
    echo "PingFederateAdmin account NOT added!"
    exit 1
fi