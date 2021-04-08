#!/bin/bash

# configure PingOne for PingFed Admin SSO

#Variables needed to be passed for this script:
# API_LOCATION
# ENV_ID
# WORKER_APP_ACCESS_TOKEN
# PINGFED_BASE_URL

echo "------ Beginning 400-pf_admin_sso_set.sh ------"

# set global api call retry limit - this can be set to desired amount, default is 2. Other try variables in script should not be modified
api_call_retry_limit=1

################## Get schema ID needed for creating attribute ##################
user_schema_try=0

function assign_schema_id() {
    # checks schema is present
    USER_SCHEMA_RESULT=$(echo $USER_SCHEMA | sed 's@.*}@@')
    if [[ "$USER_SCHEMA_RESULT" == "200" ]] && [[ "$user_schema_try" < "$api_call_retry_limit" ]] ; then
        echo "Schema available, getting ID..."
        # get signing cert id
        USER_SCHEMA_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/schemas" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.schemas[].id')
        if [[ -z "$USER_SCHEMA_ID" ]] || [[ "$USER_SCHEMA_ID" == "" ]]; then
            echo "Unable to get schema ID, retrying..."
            check_schema
        else
            echo "Schema ID set, proceeding..."
        fi
    elif [[ $SIGNING_CERT_KEYS_RESULT != "200" ]] && [[ "$user_schema_try" < "$api_call_retry_limit" ]]; then
        user_schema_tries=$((api_call_retry_limit-user_schema_try))
        echo "Unable to retrieve schema! Retrying $user_schema_tries..."
        user_schema_try=$((user_schema_try+1))
        check_schema
    else
        echo "Unable to successfully retrieve schema and exceeded try limit!"
        exit 1
    fi
}

function check_schema() {
    USER_SCHEMA=$(curl -s --write-out "%{http_code}\n" --location --request GET "$API_LOCATION/environments/$ENV_ID/schemas" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN")
    assign_schema_id
}
check_schema

#################################### check, create, or set administrator population ####################################
admin_pop_try=0

function check_admin_pop_content() {
    # verify name again
    ADMIN_POP_NAME_AGAIN=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Administrators Population") | .name')
    if [ "$ADMIN_POP_NAME_AGAIN" == "Administrators Population" ]; then
        echo "Administrators Population verified, setting population ID..."
        ADMIN_POP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Administrators Population") | .id')
        if [[ -z "$ADMIN_POP_ID" ]] || [[ "$ADMIN_POP_ID" == "" ]]; then
            echo "Administrator Population ID unable to be set correctly, retrying..."
            check_admin_pop_content
        else
            echo "Administrators Population ID set correctly..."
        fi
    else
        admin_pop_tries_left=$((api_call_retry_limit-admin_pop_try))
        echo "Unable to verify Administrators population. Retrying $admin_pop_tries_left..."
        admin_pop_try=$((admin_pop_try+1))
        check_admin_pop
    fi
}

function check_admin_pop() {
    # check name for existence
    ADMIN_POP_NAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Administrators Population") | .name')
    if [ "$ADMIN_POP_NAME" != "Administrators Population" ]; then
        echo "Administrators Population does not exist, adding..."
        # create administrators population
        CREATE_ADMIN_POP=$(curl -s --write-out "%{http_code}\n" --location --request POST "$API_LOCATION/environments/$ENV_ID/populations" \
        --header 'content-type: application/json' \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
        --data-raw '{
        "name" : "Administrators Population",
        "description" : "Administrators Population"
        }')

        CREATE_ADMIN_POP_RESULT=$(echo $CREATE_ADMIN_POP | sed 's@.*}@@')
        if [[ $CREATE_ADMIN_POP_RESULT == "201" ]]; then
            echo "Administrators Population added, beginning content check..."
            check_admin_pop_content
        elif [[ $CREATE_ADMIN_POP_RESULT != "201" ]] && [[ "$admin_pop_try" < "$api_call_retry_limit" ]]; then
            echo "Administrators Population NOT added! Checking population existence..."
            check_admin_pop_content
        else
            echo "Administrators Population NOT added and attempts to create exceeded!"
            exit 1
        fi

    else
        echo "Administrators Population found, verifying..."
        check_admin_pop_content
    fi
}
check_admin_pop

# #################################### Create PFAdmin Group ##################
admin_group_try=0

function check_admin_group_content() {
    CHECK_PF_ADMIN_GROUP_AGAIN=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/groups?filter=name%20eq%20%22PingFederate%20Administrators%22&limit=20" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    | jq -rc '._embedded.groups[] | select (.name=="PingFederate Administrators") | .name')
    if [ "$CHECK_PF_ADMIN_GROUP_AGAIN" != "PingFederate Administrators" ]; then
        admin_group_tries_left=$((api_call_retry_limit-admin_group_try))
        echo "Unable to verify content... Retrying $admin_group_tries_left more time(s)..."
        admin_group_try=$((admin_group_try+1))
        create_admin_group
    else
        echo "PingFederate Administrators group exists and verified content, setting ID variable..."
        PF_ADMIN_GROUP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/groups?filter=name%20eq%20%22PingFederate%20Administrators%22&limit=20" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
        | jq -rc '._embedded.groups[] | select (.name=="PingFederate Administrators") | .id')

        if [ -z ${PF_ADMIN_GROUP_ID+x} ]; then
            echo "Unable to set PingFederate Administrators group ID, retrying..."
            check_admin_group_content
        else
            echo "PingFederate Administrators group ID set correctly..."
        fi
    fi
}

function create_admin_group() {
    # check if admin group already exists
    CHECK_PF_ADMIN_GROUP=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/groups?filter=name%20eq%20%22PingFederate%20Administrators%22&limit=20" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    | jq -rc '._embedded.groups[] | select (.name=="PingFederate Administrators") | .name')

    if [ "$CHECK_PF_ADMIN_GROUP" != "PingFederate Administrators" ]; then
        # create PingFed Administrators group
          CREATE_PF_ADMIN_GROUP=$(curl -s --write-out "%{http_code}\n" --location --request POST "$API_LOCATION/environments/$ENV_ID/groups" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN"  --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
            --header 'Content-Type: application/json' \
            --data-raw '{
                "name" : "PingFederate Administrators",
                "description" : "User group for PingFed Admin SSO privileges.",
                "userFilter": "population.id eq \"'"$ADMIN_POP_ID"'\""
            }')
        # checks group created, as well as verify expected group name to ensure creation
        CREATE_PF_ADMIN_GROUP_RESULT=$(echo $CREATE_PF_ADMIN_GROUP | sed 's@.*}@@')
        if [[ $CREATE_PF_ADMIN_GROUP_RESULT == "201" ]]; then
            echo "PingFederate Administrators group added, beginning content check..."
            check_admin_group_content
        elif [[ $CREATE_PF_ADMIN_GROUP_RESULT != "201" ]] && [[ "$admin_group_try" < "$api_call_retry_limit" ]]; then
            echo "PingFederate Administrators group NOT added! Checking group existence..."
            check_admin_group_content
        else
            echo "PingFederate Administrators group does NOT exist and attempts to create exceeded!"
            exit 1
        fi
    else
        echo "PingFederate Administrators group existence check passed. Checking content..."
        check_admin_group_content
    fi
}
 create_admin_group

#################################### Add Web OIDC App ####################################
pf_admin_app_try=0

function check_pf_admin_app_content() {
    # check if Web OIDC App exists
    CHECK_WEB_OIDC_APP_AGAIN=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select (.name=="PingFederate Admin SSO") | .enabled')
    if [ "$CHECK_WEB_OIDC_APP_AGAIN" != "true" ]; then
        admin_app_tries_left=$((api_call_retry_limit-pf_admin_app_try))
        echo "Unable to verify content... Retrying $admin_app_tries_left..."
        pf_admin_app_try=$((pf_admin_app_try+1))
        create_pf_admin_app
    else
        echo "PingFederate Admin SSO app exists and verified content, setting variables to be used for later..."
        # this is used for functions below as well as the oidc file section at the bottom
        WEB_OIDC_APP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select (.name=="PingFederate Admin SSO") | .id')
        if [[ -z "$WEB_OIDC_APP_ID" ]] || [[ "$WEB_OIDC_APP_ID" == "" ]]; then
            echo "PingFederate Admin SSO app ID unable to be set correctly, retrying..."
            check_pf_admin_app_content
        else
            echo "PingFederate Admin SSO app ID set correctly..."
        fi
        # this is used in the run properties file section at the bottom
        OIDC_APP_NAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select (.name=="PingFederate Admin SSO") | .name')
        if [[ -z "$OIDC_APP_NAME" ]] || [[ "$OIDC_APP_NAME" == "" ]]; then
            echo "PingFederate Admin SSO app name unable to be set correctly, retrying..."
            check_pf_admin_app_content
        else
            echo "PingFederate Admin SSO app name set correctly..."
        fi
    fi
}

function create_pf_admin_app() {
    # check if Web OIDC App exists
    CHECK_WEB_OIDC_APP=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select (.name=="PingFederate Admin SSO") | .enabled')
    if [ "$CHECK_WEB_OIDC_APP" != "true" ]; then
        echo "PingFederate Admin SSO does not exist, adding now..."
        WEB_OIDC_APP=$(curl -s --write-out "%{http_code}\n" --location --request POST "$API_LOCATION/environments/$ENV_ID/applications" \
        --header 'Content-Type: application/json' \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
        --data-raw '{
            "enabled": true,
            "name": "PingFederate Admin SSO",
            "#description": " ",
            "type": "WEB_APP",
            "accessControl": {
            "role": {
            "type": "ADMIN_USERS_ONLY"
            },
            "group": {
            "type": "ANY_GROUP",
            "groups": [
                {
                "id": "'"$PF_ADMIN_GROUP_ID"'"
                }
            ]
            }
            },
            "protocol": "OPENID_CONNECT",
            "grantTypes": [
                "AUTHORIZATION_CODE"
            ],
            "redirectUris": [
                "'"https://$PINGFED_BASE_URL:443/pingfederate/app?service=finishsso"'"
            ],
            "responseTypes": [
                "CODE"
            ],
            "tokenEndpointAuthMethod": "CLIENT_SECRET_BASIC",
            "pkceEnforcement": "OPTIONAL"
        }')

        # checks app created, as well as verify expected app name to ensure creation
        WEB_OIDC_APP_RESULT=$(echo $WEB_OIDC_APP | sed 's@.*}@@')
        if [[ $WEB_OIDC_APP_RESULT == "201" ]]; then
            echo "PingFederate Admin SSO app added, beginning content check..."
            check_pf_admin_app_content
        elif [[ $WEB_OIDC_APP_RESULT != "201" ]] && [[ "$pf_admin_app_try" < "$api_call_retry_limit" ]]; then
            echo "PingFederate Admin SSO app NOT added! Checking app existence..."
            check_pf_admin_app_content
        else
            echo "PingFederate Admin SSO app does NOT exist and attempts to create exceeded!"
            exit 1
        fi
    else
        echo "PingFederate Admin SSO app existence check passed. Checking content..."
        check_pf_admin_app_content
    fi
}
create_pf_admin_app

#################################### Add attributes to PF Admin SSO App ####################################
add_name_attr_try=0

### Add name attribute to PingFederate Admin SSO App ###
function check_name_attr_content() {
    CHECK_NAME_ATTR=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications/$WEB_OIDC_APP_ID/attributes" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.attributes[] | select (.name=="name") | .name')
    if [ "$CHECK_NAME_ATTR" != "name" ]; then
        add_name_attr_try_left=$((api_call_retry_limit-add_name_attr_try))
        echo "Unable to verify name attribute content, retrying $add_name_attr_try_left more time(s) after this attempt..."
        add_name_attr
    else
        echo "name attribute verified in PingFederate Admin SSO App configuration..."
    fi
}

function add_name_attr() {
    # add name attribute to App
    NAME_ATTR=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications/$WEB_OIDC_APP_ID/attributes" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.attributes[] | select (.name=="name") | .name')
    if [ "$NAME_ATTR" != "name" ]; then
        echo "name attribute does not exist in the PingFederateAdmin SSO app configuration, adding now..."
        APP_NAME_ATTR=$(curl -s --write-out "%{http_code}\n" --location --request POST "$API_LOCATION/environments/$ENV_ID/applications/$WEB_OIDC_APP_ID/attributes" \
        --header 'Content-Type: application/json' \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
        --data-raw '{
            "name": "name",
            "value": "${user.name.formatted}",
            "required": false
        }')

        APP_NAME_ATTR_RESULT=$(echo $APP_NAME_ATTR | sed 's@.*}@@')
        if [[ $APP_NAME_ATTR_RESULT == "201" ]]; then
            echo "name attribute added to PingFederate Admin SSO app, beginning content check..."
            check_name_attr_content
        elif [[ $APP_NAME_ATTR_RESULT != "201" ]] && [[ "$add_name_attr_try" < "$api_call_retry_limit" ]]; then
            add_name_attr_try=$((add_name_attr_try+1))
            echo "name attribute NOT added to PingFederate Admin SSO app! Checking attribute existence..."
            check_name_attr_content
        else
            echo "name attribute NOT added to PingFederate Admin SSO app and attempts to create exceeded!"
            exit 1
        fi
    else
        echo "name existence check passed, checking content..."
        check_name_attr_content
    fi
}
add_name_attr

### Add Group IDs attribute to PingFederate Admin SSO App ###
add_groupid_attr_try=0

function check_groupid_attr_content() {
    GROUP_ID_ATTR=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications/$WEB_OIDC_APP_ID/attributes" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.attributes[] | select(.value=="${user.memberOfGroupIDs}") | .value')
    if [ "$GROUP_ID_ATTR" != '${user.memberOfGroupIDs}' ]; then
        add_groupid_attr_tries_left=$((api_call_retry_limit-add_groupid_attr_try))
        echo "Unable to verify Group ID attribute content, retrying $add_groupid_attr_tries_left more time(s) after this attempt..."
        add_groupid_attr_try=$((add_groupid_attr_try+1))
        add_name_attr
    else
        echo "Group ID attribute verified in PingFederate Admin SSO App configuration..."
    fi
}

function add_groupid_attr() {
    # add Group ID attribute to App
    GROUP_ID_ATTR=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications/$WEB_OIDC_APP_ID/attributes" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.attributes[] | select(.value=="${user.memberOfGroupIDs}") | .value')
    if [ "$GROUP_ID_ATTR" != '${user.memberOfGroupIDs}' ]; then
        echo "Group ID attribute does not exist in the PingFederateAdmin SSO app configuration, adding now..."
        APP_GROUP_ID=$(curl -s --write-out "%{http_code}\n" --location --request POST "$API_LOCATION/environments/$ENV_ID/applications/$WEB_OIDC_APP_ID/attributes" \
        --header 'Content-Type: application/json' \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
        --data-raw '{
            "name": "group_id",
            "value": "${user.memberOfGroupIDs}",
            "required": true
        }')

        APP_GROUP_ID_RESULT=$(echo $APP_GROUP_ID | sed 's@.*}@@')
        if [[ $APP_GROUP_ID_RESULT == "201" ]]; then
            echo "Group ID attribute added to PingFederate Admin SSO app, beginning content check..."
            check_groupid_attr_content
        elif [[ $APP_GROUP_ID_RESULT != "201" ]] && [[ "$add_pfadmin_attr_try" < "$api_call_retry_limit" ]]; then
            echo "Group ID attribute NOT added to PingFederate Admin SSO app! Checking attribute existence..."
            check_groupid_attr_content
        else
            echo "Group ID attribute NOT added to PingFederate Admin SSO app and attempts to create exceeded!"
            exit 1
        fi
    else
        echo "Group ID attribute existence check passed, checking content..."
        check_groupid_attr_content
    fi
}
add_groupid_attr

#################################### create PingFederate admin SSO Account ####################################
admin_account_try=0

function check_admin_accnt_content() {
    # get admin username
    VERIFY_ACCOUNT_UNAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/users" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.users[] | select(.username=="PingFederateAdmin") | .username')
    if [ "$VERIFY_ACCOUNT_UNAME" == "PingFederateAdmin" ]; then
        echo "PingFederateAdmin account verified, setting account ID..."
        ADMIN_ACCOUNT_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/users" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.users[] | select(.username=="PingFederateAdmin") | .id')
        if [[ -z "$ADMIN_ACCOUNT_ID" ]] || [[ "$ADMIN_ACCOUNT_ID" == "" ]]; then
            echo "PingFederateAdmin account ID unable to be set correctly, retrying..."
            check_admin_accnt_content
        else
            ADMIN_ACCOUNT_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/users" \
            --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.users[] | select(.username=="PingFederateAdmin") | .id')
            echo "PingFederateAdmin account ID set correctly..."
        fi
    else
        admin_account_tries_left=$((api_call_retry_limit-admin_account_try))
        echo "Unable to verify PingFederateAdmin account. Retrying $admin_account_tries_left..."
        admin_account_try=$((admin_account_try+1))
        check_admin_accnt
    fi
}

function check_admin_accnt() {
    # get admin username
    ADMIN_ACCOUNT_UNAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/users" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.users[] | select(.username=="PingFederateAdmin") | .username')
    #check if username matches expectation
    if [ "$ADMIN_ACCOUNT_UNAME" != "PingFederateAdmin" ]; then
        echo "PingFederateAdmin account does not exist, adding..."
        CREATE_ADMIN_ACCOUNT=$(curl -s --write-out "%{http_code}\n" --location --request POST "$API_LOCATION/environments/$ENV_ID/users" \
        --header 'content-type: application/vnd.pingidentity.user.import+json' \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
        --data-raw '{
        "email": "'"pingfederateadmin@pingidentity.com"'",
        "name": {
            "given": "Administrator",
            "family": "User"
        },
        "lifecycle": {
            "status": "ACCOUNT_OK"
        },
        "population": {
            "id": "'"$ADMIN_POP_ID"'"
        },
        "username": "PingFederateAdmin",
        "password": {
            "value": "2FederateM0re!",
            "forceChange": true
        }
        }')

        CREATE_ADMIN_ACCOUNT_RESULT=$(echo $CREATE_ADMIN_ACCOUNT | sed 's@.*}@@')
        if [[ $CREATE_ADMIN_ACCOUNT_RESULT == "201" ]]; then
            echo "PingFederateAdmin account added, beginning content check..."
            check_admin_accnt_content
        elif [[ $CREATE_ADMIN_ACCOUNT_RESULT != "201" ]] && [[ "$admin_account_try" < "$api_call_retry_limit" ]]; then
            echo "PingFederateAdmin account NOT added! Checking account existence..."
            check_admin_accnt_content
        else
            echo "PingFederateAdmin account NOT added and attempts to create exceeded!"
            exit 1
        fi

    else
        echo "PingFederateAdmin account existence check passed. Checking content..."
        check_admin_accnt_content
    fi
}
check_admin_accnt

#################################### Get environment admin role id ####################################
assign_env_role_try=0

function check_env_role_content() {
    ADMIN_ROLE=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/users/$ADMIN_ACCOUNT_ID/roleAssignments" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.roleAssignments[].scope.type')
    if [ "$ADMIN_ROLE" == "ENVIRONMENT" ]; then
        echo "PingFederateAdmin environment admin role verified..."
    else
        env_role_tries_left=$((api_call_retry_limit-assign_env_role_try))
        echo "Unable to verify PingFederateAdmin environment admin role. Retrying $env_role_tries_left..."
        assign_env_role_try=$((assign_env_role_try+1))
        check_env_role
    fi
}

function check_env_role() {
    # verify environment admin role was assigned to administrator account
    CHECK_ADMIN_ROLE=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/users/$ADMIN_ACCOUNT_ID/roleAssignments" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.roleAssignments[].scope.type')
    if [ "$CHECK_ADMIN_ROLE" != "ENVIRONMENT" ]; then
        echo "PingFederateAdmin environment admin role not assigned, assigning now..."
        ENV_ADMIN_ROLE_ID=$(curl -s --location --request GET "$API_LOCATION/roles" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.roles[] | select(.name=="Environment Admin") | .id')
        if [[ -z "$ENV_ADMIN_ROLE_ID" ]] || [[ "$ENV_ADMIN_ROLE_ID" == "" ]]; then
            echo "PingFederateAdmin environment admin role ID unable to be set correctly, retrying..."
            check_env_role
        else
            # assign environment admin role to administrator account
            ADMIN_USER_ENV_ROLE=$(curl -s --write-out "%{http_code}\n" --location --request POST "$API_LOCATION/environments/$ENV_ID/users/$ADMIN_ACCOUNT_ID/roleAssignments" \
            --header 'Content-Type: application/json' \
            --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
            --data-raw '{
                "role": {
                    "id": "'"$ENV_ADMIN_ROLE_ID"'"
                },
                "scope": {
                    "id": "'"$ENV_ID"'",
                    "type": "ENVIRONMENT"
                }
            }')

            ADMIN_USER_ENV_ROLE_RESULT=$(echo $ADMIN_USER_ENV_ROLE | sed 's@.*}@@')
            if [[ $CREATE_ADMIN_ACCOUNT_RESULT == "201" ]]; then
                echo "PingFederateAdmin environment admin role assigned, beginning content check..."
                check_env_role_content
            elif [[ $CREATE_ADMIN_ACCOUNT_RESULT != "201" ]] && [[ "$assign_env_role_try" < "$api_call_retry_limit" ]]; then
                echo "PingFederateAdmin environment admin role NOT assigned! Checking role assignment existence..."
                check_env_role_content
            else
                echo "PingFederateAdmin account NOT added and attempts to create exceeded!"
                exit 1
            fi
        fi
    else
        echo "PingFederateAdmin environment admin role ID existence check passed. Checking content..."
        check_env_role_content
    fi
}
check_env_role

#################################### export values into oidc properties tmp file ####################################

# check for existing files
OIDC_FILE="./oidc.properties.tmp"
RUN_PROP_FILE="./run.properties.tmp"

function write_oidc_file_out {

    # get, set oidc content, this is very important for creating the file later
    oauth_cons_try=0
    function oidc_content() {
        OIDC_APP_OAUTH_CONTENT_CHECK=$(curl -s --write-out "%{http_code}\n" --location --request GET "https://auth.pingone.com/$ENV_ID/as/.well-known/openid-configuration")
        OIDC_APP_OAUTH_CONTENT_CHECK_RESULT=$(echo $OIDC_APP_OAUTH_CONTENT_CHECK | sed 's@.*}@@')
        if [ $OIDC_APP_OAUTH_CONTENT_CHECK_RESULT == "200" ]; then
            echo "openid configuration content found, setting to be used for other variables..."
            OIDC_APP_OAUTH_CONTENT=$(curl -s --location --request GET "https://auth.pingone.com/$ENV_ID/as/.well-known/openid-configuration")
            APP_AUTH_EP=$( echo "$OIDC_APP_OAUTH_CONTENT" | jq -rc '.authorization_endpoint' )
            APP_TOKEN_EP=$( echo "$OIDC_APP_OAUTH_CONTENT" | jq -rc '.token_endpoint' )
            APP_USERINFO_EP=$( echo "$OIDC_APP_OAUTH_CONTENT" | jq -rc '.userinfo_endpoint' )
            APP_SO_EP=$( echo "$OIDC_APP_OAUTH_CONTENT" | jq -rc '.end_session_endpoint' )
            APP_ISSUER=$( echo "$OIDC_APP_OAUTH_CONTENT" | jq -rc '.issuer' )
            APP_SCOPES=$( echo "$OIDC_APP_OAUTH_CONTENT" | jq -rc '.scopes_supported' | sed -e 's/\[//g' -e 's/\"/ /g' -e 's/ //g' -e 's/\,/ /g' -e 's/\]//g')
        elif [[ $OIDC_APP_OAUTH_CONTENT_CHECK_RESULT != "200" ]] && [[ "$oauth_cons_try" < "$api_call_retry_limit" ]]; then
            oauth_cons_tries_left=$((api_call_retry_limit-oauth_cons_try))
            echo "Unable to get openid configuration content, retrying $oauth_cons_tries_left..."
            oauth_cons_try=$((oauth_cons_try+1))
            oidc_content
        else
            echo "Unable to retrieve openid configuration content and set other variables. Maximum attempts exceeded!"
            exit 1
        fi
    }
    oidc_content

    # get, set client secret from PingFederateAdmin SSO app
    client_secret_try=0
    function client_secret() {
        APP_CLIENT_SECRET_CHECK=$(curl -s --write-out "%{http_code}\n" --location --request GET "$API_LOCATION/environments/$ENV_ID/applications/$WEB_OIDC_APP_ID/secret" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN")
        APP_CLIENT_SECRET_CHECK_RESULT=$(echo $APP_CLIENT_SECRET_CHECK | sed 's@.*}@@')
        if [ $APP_CLIENT_SECRET_CHECK_RESULT == "200" ]; then
            echo "app client secret found, setting..."
            APP_CLIENT_SECRET=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications/$WEB_OIDC_APP_ID/secret" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '.secret')
        elif [[ $APP_CLIENT_SECRET_CHECK_RESULT != "200" ]] && [[ "$client_secret_try" < "$api_call_retry_limit" ]]; then
            client_secret_tries_left=$((api_call_retry_limit-client_secret_try))
            echo "Unable to retrieve app client secret, retrying $client_secret_tries_left..."
            client_secret_try=$((client_secret_try+1))
            client_secret
        else
            echo "Unable to retrieve app client secret content. Maximum attempts exceeded!"
            exit 1
        fi
    }
    client_secret

    # get, set client secret from PingFederateAdmin SSO app
    attributes_try=0
    function attributes () {
        ATTRIBUTE_CHECK=$(curl -s --write-out "%{http_code}\n" --location --request GET "$API_LOCATION/environments/$ENV_ID/applications/$WEB_OIDC_APP_ID/attributes" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN")
        ATTRIBUTE_CHECK_RESULT=$(echo $ATTRIBUTE_CHECK | sed 's@.*}@@')
        if [ $APP_CLIENT_SECRET_CHECK_RESULT == "200" ]; then
            echo "attributes found, setting other variables..."
            APP_USERNAME_ATTRIBUTE=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications/$WEB_OIDC_APP_ID/attributes" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.attributes[] | select(.value=="${user.name.formatted}") | .name')
            APP_ATTR_NAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications/$WEB_OIDC_APP_ID/attributes" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.attributes[] | select(.value=="${user.memberOfGroupIDs}") | .name' )
        elif [[ $APP_CLIENT_SECRET_CHECK_RESULT != "200" ]] && [[ "$attributes_try" < "$api_call_retry_limit" ]]; then
            attributes_tries_left=$((api_call_retry_limit-attributes_try))
            echo "Unable to retrieve attributes, retrying $attributes_tries_left more time(s)..."
            attributes_try=$((attributes_try+1))
            attributes
        else
            echo "Unable to retrieve attributes. Maximum attempts exceeded!"
            exit 1
        fi
    }
    attributes

    # get, set role name from PingFederateAdmin SSO app
    role_name_try=0
    function role_name() {
        APP_ROLE_NAME_CHECK=$(curl -s --write-out "%{http_code}\n" --location --request GET "$API_LOCATION/environments/$ENV_ID/users/$ADMIN_ACCOUNT_ID?expand=population" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN")
        APP_ROLE_NAME_CHECK_RESULT=$(echo $APP_ROLE_NAME_CHECK | sed 's@.*}@@')
        if [ $APP_ROLE_NAME_CHECK_RESULT == "200" ]; then
            echo "role name found, setting..."
            APP_ROLE_NAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/users/$ADMIN_ACCOUNT_ID?expand=population" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '."pf-admin-role"')
        elif [[ $APP_ROLE_NAME_CHECK_RESULT != "200" ]] && [[ "$role_name_try" < "$api_call_retry_limit" ]]; then
            role_name_tries_left=$((api_call_retry_limit-role_name_try))
            echo "Unable to retrieve role name, retrying $role_name_tries_left..."
            role_name_try=$((role_name_try+1))
            role_name
        else
            echo "Unable to retrieve role name. Maximum attempts exceeded!"
            exit 1
        fi
    }
    role_name

    function client_id() {
    if [[ -z "$WEB_OIDC_APP_ID" ]] || [[ "$WEB_OIDC_APP_ID" == "" ]]; then
        echo "Could not initially find PingFederateAdmin SSO app ID, sending to get this variable in above function..."
        check_pf_admin_app_content
    else
        echo "Setting client id from PingFederateAdmin SSO app ID..."
        APP_CLIENT_ID="$WEB_OIDC_APP_ID"
    fi
    }
    client_id

    #set variable already known
    APP_AUTHN_METHOD="client_secret_basic"

### Output variables to OIDC properties file ###
    echo "PF_OIDC_CLIENT_ID=$APP_CLIENT_ID" >> $OIDC_FILE
    echo "PF_OIDC_CLIENT_AUTHN_METHOD=$APP_AUTHN_METHOD" >> $OIDC_FILE
    # the client secret maybe need to be run against obfuscate script in PingFederate
    echo "PF_OIDC_CLIENT_SECRET=$APP_CLIENT_SECRET" >> $OIDC_FILE
    echo "PF_OIDC_AUTHORIZATION_ENDPOINT=$APP_AUTH_EP" >> $OIDC_FILE
    echo "PF_OIDC_TOKEN_ENDPOINT=$APP_TOKEN_EP" >> $OIDC_FILE
    echo "PF_OIDC_USER_INFO_ENDPOINT=$APP_USERINFO_EP" >> $OIDC_FILE
    echo "PF_OIDC_END_SESSION_ENDPOINT=$APP_SO_EP" >> $OIDC_FILE
    echo "PF_OIDC_ISSUER=$APP_ISSUER" >> $OIDC_FILE
    echo "PF_OIDC_ACR_VALUES=" >> $OIDC_FILE
    echo "PF_OIDC_SCOPES=$APP_SCOPES" >> $OIDC_FILE
    echo "PF_OIDC_USERNAME_ATTRIBUTE_NAME=sub" >> $OIDC_FILE
    echo "PF_OIDC_ROLE_ATTRIBUTE_NAME=$APP_ATTR_NAME" >> $OIDC_FILE
    echo "PF_OIDC_ROLE_ADMIN=$PF_ADMIN_GROUP_ID" >> $OIDC_FILE
    echo "PF_OIDC_ROLE_CRYPTOMANAGER=$PF_ADMIN_GROUP_ID" >> $OIDC_FILE
    echo "PF_OIDC_ROLE_USERADMIN=$PF_ADMIN_GROUP_ID" >> $OIDC_FILE
    echo "PF_OIDC_ROLE_EXPRESSIONADMIN=eadmin" >> $OIDC_FILE
    echo "PF_OIDC_ROLE_AUDITOR=" >> $OIDC_FILE
    echo "oidc.properties.tmp file written..."
}

# handles existing oidc file, or creates said file
if [ -f "$OIDC_FILE" ]; then
    echo "Existing oidc file present, taking care of that..."
    mv $OIDC_FILE "$OIDC_FILE.old"
    echo -n "" > "$OIDC_FILE.old"
    echo "Existing oidc file named to $OIDC_FILE.old"
    write_oidc_file_out
else
    echo "No existing oidc file, creating now..."
    write_oidc_file_out
fi

#################################### write out run.properties.tmp file ####################################
function write_prop_file_out {

    # export values into run properties tmp file
    function hostname() {
    if [[ -z "$PINGFED_BASE_URL" ]] || [[ "$PINGFED_BASE_URL" == "" ]]; then
        echo "PINGFED_BASE_URL variable not set! This is needed to proceed with creating the run.properties.tmp file!"
        exit 1
    else
        echo "PINGFED_BASE_URL variable value found, setting variable for run.properties.tmp file..."
        PF_ADMIN_HOSTNAME="$PINGFED_BASE_URL"
    fi
    }
    hostname

    admin_env_try=0
    function admin_env_id() {
        ADMIN_ENV_ID_CHECK=$(curl -s --write-out "%{http_code}\n" --location --request GET "$API_LOCATION/environments/$ENV_ID" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN")
        ADMIN_ENV_ID_CHECK_RESULT=$(echo $ADMIN_ENV_ID_CHECK | sed 's@.*}@@')
        if [ $ADMIN_ENV_ID_CHECK_RESULT == "200" ]; then
            echo "Administrators Environment Found, setting ID..."
            ADMIN_ENV_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '. | select(.name="Administrators") | .id')
        elif [[ $ADMIN_ENV_ID_CHECK_RESULT != "200" ]] && [[ "$admin_env_try" < "$api_call_retry_limit" ]]; then
            admin_env_tries_left=$((api_call_retry_limit-admin_env_try))
            echo "Unable to retrieve Administrators Environment, retrying $admin_env_tries_left..."
            admin_env_try=$((admin_env_try+1))
            admin_env_id
        else
            echo "Unable to retrieve Administrators Environment ID. Maximum attempts exceeded!"
            exit 1
        fi
    }
    admin_env_id

### Output variables to run properties file ###
    echo "PF_ADMIN_PUBLIC_HOSTNAME=$PF_ADMIN_HOSTNAME" >> $RUN_PROP_FILE
    echo "PF_ADMIN_CONSOLE_TITLE=$OIDC_APP_NAME" >> $RUN_PROP_FILE
    echo "PF_ADMIN_CONSOLE_ENVIRONMENT=$ADMIN_ENV_ID" >> $RUN_PROP_FILE
    echo "PF_CONSOLE_AUTHENTICATION=OIDC" >> $RUN_PROP_FILE
    echo "run.properties.tmp file written..."
}

# handles existing properties file, or creates said file
if [ -f "$RUN_PROP_FILE" ]; then
    echo "Existing properties file present, taking care of that..."
    mv $RUN_PROP_FILE "$RUN_PROP_FILE.old"
    echo -n "" > "$RUN_PROP_FILE.old"
    echo "Existing properties file named to $RUN_PROP_FILE.old"
    write_prop_file_out
else
    echo "No existing properties file, creating now..."
    write_prop_file_out
fi


echo "------ End of 400-pf_admin_sso_set.sh ------"