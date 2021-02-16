#!/bin/bash

# revert PingOne for PingFed Admin SSO

#Variables needed to be passed for this script:
# API_LOCATION=
# ENV_ID
# WORKER_APP_ACCESS_TOKEN

# check if admin account exists, get expected username
CHECK_ADMIN_ACCOUNT=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/users" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.users[] | select(.username=="PingFederateAdmin") | .username')

# check, delete admin account
if [ "$CHECK_ADMIN_ACCOUNT" == "PingFederateAdmin" ]; then
    echo "PingFederate Admin account found, removing..."

    # get admin user id
    ADMIN_ACCOUNT_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/users" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.users[] | select(.username=="PingFederateAdmin") | .id')

    # remove admin account
    REMOVE_ADMIN_ACCOUNT=$(curl -s --write-out "%{http_code}\n" --location --request DELETE "$API_LOCATION/environments/$ENV_ID/users/$ADMIN_ACCOUNT_ID" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" --data-raw '')

    # check response code
    REMOVE_ADMIN_ACCOUNT_RESULT=$(echo $REMOVE_ADMIN_ACCOUNT | sed 's@.*}@@' )
    if [ $REMOVE_ADMIN_ACCOUNT_RESULT == "204" ] ; then
        echo "PingFederate Admin account removed successfully..."
    else
        echo "PingFederate Admin account was NOT removed successfully..."
        exit 1
    fi

else
    echo "PingFederate Admin account not found does not currently exist, proceeding to next step..."
fi

# check, delete administrator population - this must be done before removing admin user
ADMIN_POP_NAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Administrators Population") | .name')

if [ "$ADMIN_POP_NAME" == "Administrators Population" ]; then
    echo "Existing Administrators Population found, removing..."

    # get administrators population ID
    ADMIN_POP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Administrators Population") | .id')

    # delete administrators population
    DELETE_ADMIN_POP=$(curl -s --write-out "%{http_code}\n" --location --request DELETE "$API_LOCATION/environments/$ENV_ID/populations/$ADMIN_POP_ID" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" --data-raw '')

    # check response code
    DELETE_ADMIN_POP_RESULT=$(echo $DELETE_ADMIN_POP | sed 's@.*}@@' )
    if [ $DELETE_ADMIN_POP_RESULT == "204" ] ; then
        echo "Administrators Populaton removed successfully..."
    else
        echo "Administrators Populaton was NOT removed successfully..."
        exit 1
    fi

else
    echo "Expected Administrators Population does not currently exist, proceeding to next step..."
fi

# check if Web OIDC App exists, enabled
CHECK_WEB_OIDC_APP=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select (.name=="PingFederate Admin SSO") | .enabled')

# check, delete Web OIDC App
if [ "$CHECK_WEB_OIDC_APP" == "true" ]; then
    echo "PingFederate Admin SSO App present, removing..."

    # get Web OIDC App ID
    WEB_OIDC_APP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select (.name=="PingFederate Admin SSO") | .id')

    # delete Web OIDC App
    DELETE_OIDC_APP=$(curl -s --write-out "%{http_code}\n" --location --request DELETE "$API_LOCATION/environments/$ENV_ID/applications/$WEB_OIDC_APP_ID" \
    --header 'Content-Type: application/json' --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" --data-raw '')

    # check response code
    DELETE_OIDC_APP_RESULT=$(echo $DELETE_OIDC_APP | sed 's@.*}@@' )
    if [ $DELETE_OIDC_APP_RESULT == "204" ] ; then
        echo "PingFederate Admin SSO App removed successfully..."
    else
        echo "PingFederate Admin SSO App was NOT removed successfully..."
        exit 1
    fi

else
    echo "Expected PingFederate Admin SSO App does not currently exist, proceeding to next step..."
fi

# get schema ID needed for removing attribute
USER_SCHEMA_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/schemas" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.schemas[].id')

# check, delete PingFed Admin Role
CHECK_ADMIN_ATTRIBUTE=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/schemas/$USER_SCHEMA_ID/attributes" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.attributes[] | select (.name=="pf-admin-roles") | .enabled')

if [ "$CHECK_ADMIN_ATTRIBUTE" == "true" ]; then
    echo "PingFederate Admin attribute present, removing..."

    # get admin attribute ID
    ADMIN_ATTRIBUTE_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/schemas/$USER_SCHEMA_ID/attributes" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.attributes[] | select (.name=="pf-admin-roles") | .id')

    # remove PingFed Admin Role attribute
    DELETE_PF_ADMIN_ATTRIBUTE=$(curl -s --write-out "%{http_code}\n" --location --request DELETE "$API_LOCATION/environments/$ENV_ID/schemas/$USER_SCHEMA_ID/attributes/$ADMIN_ATTRIBUTE_ID" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" --data-raw '')

    # check response code
    DELETE_PF_ADMIN_ATTRIBUTE_RESULT=$(echo $DELETE_PF_ADMIN_ATTRIBUTE | sed 's@.*}@@' )
    if [ $DELETE_PF_ADMIN_ATTRIBUTE_RESULT == "204" ] ; then
        echo "PingFederate Admin attribute removed successfully..."
    else
        echo "PingFederate Admin attribute was NOT removed successfully..."
        exit 1
    fi

else
    echo "PingFederate Admin attribute does not currently exist..."
fi

echo "Checks and tasks completed..."