#!/bin/bash

# revert PingOne for PingFed Admin SSO

#Variables needed to be passed for this script:
# API_LOCATION
# ADMIN_ENV_ID
# WORKER_APP_ACCESS_TOKEN

# set global api call retry limit - this can be set to desired amount, default is 1
api_call_retry_limit=1

echo "------ Beginning 400-pf_admin_sso_revert.sh ------"

    #################################### get administrator env ####################################
    admin_env_try=0

    function get_admin_env() {
        # checks org is present
        if [[ "$ORG_ID" =~ ^\{?[A-F0-9a-f]{8}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{12}\}?$ ]] && [[ "$admin_env_try" < "$api_call_retry_limit" ]] ; then
            echo "Org info available, getting ID..."
            ADMIN_ENV_NM='Administrators'
            # get env id
            ADMIN_ENV_ID=$(curl -s --location --request GET "$ORG_HREF/environments/" \
            --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | \
            jq -rc '._embedded.environments[] | select(.name=="'"$ADMIN_ENV_NM"'") | .id')
            if [[ -z "$ADMIN_ENV_ID" ]] || [[ "$ADMIN_ENV_ID" == "" ]]; then
                echo "Unable to get ADMIN ENV ID, retrying..."
                admin_env_try=$((admin_env_try+1))
                check_admin_env
            else
                AS_ENDPOINT=$(echo "$AUTH_SERVER_BASE_URL/$ADMIN_ENV_ID/as")
                echo "ADMIN ENV ID set, proceeding..."
            fi
        else
            echo "Unable to successfully retrieve Admin ENV ID and exceeded try limit!"
            exit 1
        fi
    }

    function check_admin_env() {
        ENV_GET=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN")

        ORG_ID=$(echo "$ENV_GET" | jq -rc '.organization.id')
        ORG_HREF=$(echo "$ENV_GET" | jq -rc '._links.organization.href')

        get_admin_env
    }
    check_admin_env

    #################################### finish get admin env ####################################

# check if admin account exists, get expected username
CHECK_ADMIN_ACCOUNT=$(curl -s --location --request GET "$API_LOCATION/environments/$ADMIN_ENV_ID/users" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.users[] | select(.username=="PingFederateAdmin") | .username')

# check, delete admin account - this must be done before removing a population
if [ "$CHECK_ADMIN_ACCOUNT" == "PingFederateAdmin" ]; then
    echo "PingFederate Admin account found, removing..."

    # get admin user id
    ADMIN_ACCOUNT_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ADMIN_ENV_ID/users" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.users[] | select(.username=="PingFederateAdmin") | .id')

    # remove admin account
    REMOVE_ADMIN_ACCOUNT=$(curl -s --write-out "%{http_code}\n" --location --request DELETE "$API_LOCATION/environments/$ADMIN_ENV_ID/users/$ADMIN_ACCOUNT_ID" \
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

# Commented section in case user wants to keep Administrator population
# # check administrator population
# ADMIN_POP_NAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ADMIN_ENV_ID/populations" \
# --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Administrators Population") | .name')

# # check, delete administrator population
# if [ "$ADMIN_POP_NAME" == "Administrators Population" ]; then
#     echo "Existing Administrators Population found, removing..."

#     # get administrators population ID
#     ADMIN_POP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ADMIN_ENV_ID/populations" \
#     --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Administrators Population") | .id')

#     # delete administrators population
#     DELETE_ADMIN_POP=$(curl -s --write-out "%{http_code}\n" --location --request DELETE "$API_LOCATION/environments/$ADMIN_ENV_ID/populations/$ADMIN_POP_ID" \
#     --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" --data-raw '')

#     # check response code
#     DELETE_ADMIN_POP_RESULT=$(echo $DELETE_ADMIN_POP | sed 's@.*}@@' )
#     if [ $DELETE_ADMIN_POP_RESULT == "204" ] ; then
#         echo "Administrators Populaton removed successfully..."
#     else
#         echo "Administrators Populaton was NOT removed successfully..."
#         exit 1
#     fi

# else
#     echo "Expected Administrators Population does not currently exist, proceeding to next step..."
# fi

    # #################################### Create PFAdmin Group ##################
    admin_group_try=0

function delete_admin_group() {
    # check if admin group already exists
    CHECK_PF_ADMIN_GROUP=$(curl -s --location --request GET "$API_LOCATION/environments/$ADMIN_ENV_ID/groups?filter=name%20eq%20%22PingFederate%20Administrators%22&limit=20" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    | jq -rc '._embedded.groups[] | select (.name=="PingFederate Administrators") | .name')
    if [ "$CHECK_PF_ADMIN_GROUP" == "PingFederate Administrators" ]; then
        # get PingFed Administrators group id
        echo "Me findy PingFeddy group."
        PF_GROUP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ADMIN_ENV_ID/groups?filter=name%20eq%20%22PingFederate%20Administrators%22&limit=20" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
                      | jq -rc '._embedded.groups[] | select (.name=="PingFederate Administrators") | .id')
        DELETE_PF_GROUP=$(curl -s --write-out "%{http_code}\n" --location --request DELETE "$API_LOCATION/environments/$ADMIN_ENV_ID/groups/$PF_GROUP_ID"\
                          --header 'Content-Type: application/json' --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN")
        # checks group created, as well as verify expected group name to ensure creation
        DELETE_PF_ADMIN_GROUP_RESULT=$(echo $DELETE_PF_GROUP | sed 's@.*}@@')
        if [[ $DELETE_PF_ADMIN_GROUP_RESULT == "204" ]]; then
            echo "PingFederate Administrators group deleted successfully..."
        elif [[ $DELETE_PF_ADMIN_GROUP_RESULT != "204" ]] && [[ "$admin_group_try" < "$api_call_retry_limit" ]]; then
            echo "PingFederate Administrators group NOT deleted. Checking group existence..."
            delete_admin_group
        else
            echo "PingFederate Administrators group attempts to evict exceeded!"
        fi
    else
        echo "PingFederate Administrators group exist not"
    fi
}
 delete_admin_group


# check if Web OIDC App exists, enabled
CHECK_WEB_OIDC_APP=$(curl -s --location --request GET "$API_LOCATION/environments/$ADMIN_ENV_ID/applications" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select (.name=="PingFederate Admin SSO") | .enabled')

# check, delete Web OIDC App
if [ "$CHECK_WEB_OIDC_APP" == "true" ]; then
    echo "PingFederate Admin SSO App present, removing..."

    # get Web OIDC App ID
    WEB_OIDC_APP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ADMIN_ENV_ID/applications" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select (.name=="PingFederate Admin SSO") | .id')

    # delete Web OIDC App
    DELETE_OIDC_APP=$(curl -s --write-out "%{http_code}\n" --location --request DELETE "$API_LOCATION/environments/$ADMIN_ENV_ID/applications/$WEB_OIDC_APP_ID" \
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

#no longer creating schema ID in create
## get schema ID needed for removing attribute
#USER_SCHEMA_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ADMIN_ENV_ID/schemas" \
#--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.schemas[].id')
#
## check, delete PingFed Admin Role
#CHECK_ADMIN_ATTRIBUTE=$(curl -s --location --request GET "$API_LOCATION/environments/$ADMIN_ENV_ID/schemas/$USER_SCHEMA_ID/attributes" \
#--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.attributes[] | select (.name=="pf-admin-role") | .enabled')
#
#if [ "$CHECK_ADMIN_ATTRIBUTE" == "true" ]; then
#    echo "PingFederate Admin attribute present, removing..."
#
#    # get admin attribute ID
#    ADMIN_ATTRIBUTE_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ADMIN_ENV_ID/schemas/$USER_SCHEMA_ID/attributes" \
#    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.attributes[] | select (.name=="pf-admin-role") | .id')
#
#    # remove PingFed Admin Role attribute
#    DELETE_PF_ADMIN_ATTRIBUTE=$(curl -s --write-out "%{http_code}\n" --location --request DELETE "$API_LOCATION/environments/$ADMIN_ENV_ID/schemas/$USER_SCHEMA_ID/attributes/$ADMIN_ATTRIBUTE_ID" \
#    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" --data-raw '')
#
#    # check response code
#    DELETE_PF_ADMIN_ATTRIBUTE_RESULT=$(echo $DELETE_PF_ADMIN_ATTRIBUTE | sed 's@.*}@@' )
#    if [ $DELETE_PF_ADMIN_ATTRIBUTE_RESULT == "204" ] ; then
#        echo "PingFederate Admin attribute removed successfully..."
#    else
#        echo "PingFederate Admin attribute was NOT removed successfully..."
#        exit 1
#    fi
#
#else
#    echo "PingFederate Admin attribute does not currently exist..."
#fi

echo "Checks and tasks completed..."

echo "------ End 400-pf_admin_sso_revert.sh ------"