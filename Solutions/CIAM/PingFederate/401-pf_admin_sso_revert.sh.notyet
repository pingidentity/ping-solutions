#!/bin/bash

# revert PingOne for PingFed Admin SSO

#Variables needed to be passed for this script:
# PINGFED_BASE_URL
# DOMAIN

PF_ADMIN=$(curl -s --insecure --location --request GET "$PINGFED_BASE_URL:9999/pf-admin-api/v1/administrativeAccounts" \
--header 'X-XSRF-Header: pingfederate' \
--header 'Authorization: Basic QWRtaW5pc3RyYXRvcjoyRmVkZXJhdGVNMHJl' | jq -rc '.items[] | select(.username=="PingFederateAdmin") | .username')

if [ "$PF_ADMIN" == "PingFederateAdmin" ] ; then
    echo "PingFederateAdmin account located in PingFederate, removing..."

    PF_ADMIN=$(curl -s --write-out "%{http_code}\n" --insecure --location --request DELETE "$PINGFED_BASE_URL:9999/pf-admin-api/v1/administrativeAccounts/PingFederateAdmin" \
    --header 'Content-Type: application/json' \
    --header 'X-XSRF-Header: pingfederate' \
    --header 'Authorization: Basic QWRtaW5pc3RyYXRvcjoyRmVkZXJhdGVNMHJl' \
    --data-raw '')

    PF_ADMIN_RESULT=$(echo $PF_ADMIN | sed 's@.*}@@')
    if [ $PF_ADMIN_RESULT == "204" ] ; then
        echo "Removed PingFederateAdmin account..."
    else
        echo "PingFederateAdmin account NOT removed successfully!"
        exit 1
    fi
else
    echo "PingFederateAdmin account NOT found, exiting!"
    exit 1
fi