#!/bin/bash

# configure PingOne for PingFed Admin SSO

#Variables needed to be passed for this script:
API_LOCATION="https://api.pingone.com/v1"
ENV_ID="ae276c77-af5c-4ae5-a82d-be219cf1b6ea"
WORKER_APP_ACCESS_TOKEN="eyJhbGciOiJSUzI1NiIsImtpZCI6ImRlZmF1bHQifQ.eyJjbGllbnRfaWQiOiJhNTdiYTkyMS1iNDAzLTQ0NWMtOTRiMi1kMTJkZTg5YjUzYmUiLCJpc3MiOiJodHRwczovL2F1dGgucGluZ29uZS5jb20vYWUyNzZjNzctYWY1Yy00YWU1LWE4MmQtYmUyMTljZjFiNmVhL2FzIiwiaWF0IjoxNjE0ODk0MTgyLCJleHAiOjE2MTQ4OTc3ODIsImF1ZCI6WyJodHRwczovL2FwaS5waW5nb25lLmNvbSJdLCJlbnYiOiJhZTI3NmM3Ny1hZjVjLTRhZTUtYTgyZC1iZTIxOWNmMWI2ZWEiLCJvcmciOiIyMDQ4YjAxZC0xMjFlLTRiZWEtODc1MC1kMzNkZTY4ZmQ2ZGUifQ.UQ4mS1L0I7-aLROYu3pp4J2jzKFs08fjRd0HJQAHd5Im0t3Q0xE7Vynjnw7IbjkXmNEm7nEzQruMQXsXgRnWY23NF_bbq4iWnyS92XMGI47lL10xnml_cEa9oO5mFRRiU8OabcWR8zohEiCQKLWjbabAOYu3K72jcamNos2R0b9OD7zcJsjfu_j86bKMLVsMnriV4PKDmh85mVxqHAfUpEbqpGqCiAlVEv3T0WgJ4VZBoItSGVNP4tH1yE_l1P3p3fdw9nCvEnDhtvIgHxFdeTXoRWY_81UGsHUz2l9xHGnX9cwoEHoks7GB_IfkAJgIXvLVWTaLBIAOhN2X1TwH3Q"
PINGFED_BASE_URL="https://localhost"
DOMAIN="example.com"

# set global api call retry limit - this can be set to desired amount, default is 2
api_call_retry_limit=2

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
        if [ -z "$USER_SCHEMA_ID" ]; then
            echo "Unable to get schema ID, retrying..."
            check_schema
        else
            echo "Schema ID set, proceeding..."
        fi
    elif [[ $SIGNING_CERT_KEYS_RESULT != "200" ]] && [[ "$user_schema_try" < "$api_call_retry_limit" ]]; then
        signing_key_id_try=$((api_call_retry_limit-user_schema_try))
        echo "Unable to retrieve schema! Retrying $user_schema_try more time(s)..."
        check_schema
    else
        echo "Unable to successfully retrieve schema and exceeded try limit!"
        exit 1
    fi
}

function check_schema() {
    USER_SCHEMA=$(curl -s --write-out "%{http_code}\n" --location --request GET "$API_LOCATION/environments/$ENV_ID/schemas" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN")
    user_schema_try=$((user_schema_try+1))
    assign_schema_id
}
check_schema

#################################### Check to make sure PingFed Admin Role was created ##################
admin_attr_try=0

function check_admin_attr_content() {
    CHECK_ADMIN_ATTRIBUTE_AGAIN=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/schemas/$USER_SCHEMA_ID/attributes" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    | jq -rc '._embedded.attributes[] | select (.name=="pf-admin-role") | .enabled')
    if [ "$CHECK_ADMIN_ATTRIBUTE_AGAIN" != "true" ]; then
        admin_attr_tries_left=$((api_call_retry_limit-admin_attr_try))
        echo "Unable to verify content... Retrying $admin_attr_try more time(s)"
        create_admin_attr
    else
        echo "PingFederate Admin attribute exists and verified content..."
    fi
}

function create_admin_attr() {
    # check if admin attribute already exists
    CHECK_ADMIN_ATTRIBUTE=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/schemas/$USER_SCHEMA_ID/attributes" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.attributes[] | select (.name=="pf-admin-role") | .enabled')

    if [ "$CHECK_ADMIN_ATTRIBUTE" != "true" ]; then
        # create PingFed Admin Role attribute
        PF_ADMIN_ATTRIBUTE=$(curl -s --write-out "%{http_code}\n" --write-out "%{http_code}\n" --location --request POST "$API_LOCATION/environments/$ENV_ID/schemas/$USER_SCHEMA_ID/attributes" \
        --header 'Content-Type: application/json' \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
        --data-raw '{
        "description": " ",
        "displayName": "PingFed Admin Role",
        "enabled": true,
        "name": "pf-admin-role",
        "required": false,
        "type": "STRING",
        "unique": false
        }')

        # checks app created, as well as verify expected app name to ensure creation
        PF_ADMIN_ATTRIBUTE_RESULT=$(echo $PF_ADMIN_ATTRIBUTE | sed 's@.*}@@')
        if [[ $PF_ADMIN_ATTRIBUTE_RESULT == "201" ]]; then
            echo "PingFederate Admin attribute added, beginning content check..."
            check_admin_attr_content
        elif [[ $PF_ADMIN_ATTRIBUTE_RESULT != "201" ]] && [[ "$admin_attr_try" < "$api_call_retry_limit" ]]; then
            ssr_app_try=$((admin_attr_try+1))
            echo "Self-Service Registration demo app NOT added! Checking app existence..."
            check_admin_attr_content
        else
            echo "Self-Service Registration demo app does NOT exist and attempts to create exceeded!"
            exit 1
        fi
    else
        echo "PF Admin attribute existence check passed. Checking content..."
        check_admin_attr_content
    fi
}

create_admin_attr

#################################### Add Web OIDC App ####################################
pf_admin_app_try=0

function check_pf_admin_app_content() {
    # check if Web OIDC App exists
    CHECK_WEB_OIDC_APP_AGAIN=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select (.name=="PingFederate Admin SSO") | .enabled')

    if [ "$CHECK_WEB_OIDC_APP_AGAIN" != "true" ]; then
        admin_app_tries_left=$((api_call_retry_limit-pf_admin_app_try))
        echo "Unable to verify content... Retrying $admin_app_tries_left more time(s)"
        create_pf_admin_app
    else
        echo "PingFederate Admin SSO app exists and verified content, setting app ID to be used for later..."
        # set ID for later
        WEB_OIDC_APP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select (.name=="PingFederate Admin SSO") | .id')
    fi
}

function create_pf_admin_app() {
    # check if Web OIDC App exists
    CHECK_WEB_OIDC_APP=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select (.name=="PingFederate Admin SSO") | .enabled')

    if [ "$CHECK_WEB_OIDC_APP" != "true" ]; then
        WEB_OIDC_APP=$(curl -s --write-out "%{http_code}\n" --location --request POST "$API_LOCATION/environments/$ENV_ID/applications" \
        --header 'Content-Type: application/json' \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
        --data-raw '{
            "enabled": true,
            "name": "PingFederate Admin SSO",
            "#description": " ",
            "type": "WEB_APP",
            "protocol": "OPENID_CONNECT",
            "grantTypes": [
                "AUTHORIZATION_CODE"
            ],
            "redirectUris": [
                "'"$PINGFED_BASE_URL:9999/pingfederate/app?service=finishsso"'"
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
            pf_admin_app_try=$((pf_admin_app_try+1))
            echo "PingFederate Admin SSO app NOT added! Checking app existence..."
            check_pf_admin_app_content
        else
            echo "PingFederate Admin SSO app does NOT exist and attempts to create exceeded!"
            exit 1
        fi
    else
        echo "PF Admin SSO app existence check passed. Checking content..."
        check_pf_admin_app_content
    fi
}

create_pf_admin_app

#################################### Add attributes to PF Admin SSO App ####################################
add_name_attr_try=0
add_sub_attr_try=0
add_pfadmin_attr_try=0

### Add name attribute to PingFederate Admin SSO App ###
function check_name_attr_content() {
    NAME_ATTR=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications/$WEB_OIDC_APP_ID/attributes" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.attributes[] | select (.name=="name") | .name')
    if [ "$NAME_ATTR" != "name" ]; then
        add_name_attr_try_left=$((api_call_retry_limit-add_name_attr_try))
        echo "Unable to verify name attribute content, retrying $add_name_attr_try_left more time(s)..."
        add_name_attr
    else
        echo "name attribute verified in PingFederate Admin SSO App configuration..."
    fi
}

function add_name_attr() {
    # add name attribute to App
    APP_NAME_ATTR=$(curl -s --write-out "%{http_code}\n" --location --request POST "$API_LOCATION/environments/$ENV_ID/applications/$WEB_OIDC_APP_ID/attributes" \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    --data-raw '{
        "name": "name",
        "value": "${user.name.formatted}",
        "required": true
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
}

add_name_attr

### Add pf-admin-role attribute to PingFederate Admin SSO App ###
function check_pfadmin_attr_content() {
    PF_ADMIN_ROLE_ATTR=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications/$WEB_OIDC_APP_ID/attributes" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.attributes[] | select (.name=="pf-admin-role") | .name')
    if [ "$PF_ADMIN_ROLE_ATTR" != "pf-admin-role" ]; then
        add_name_attr_try_left=$((api_call_retry_limit-add_name_attr_try))
        echo "Unable to verify pf-admin-role attribute content, retrying $add_name_attr_try_left more time(s)..."
        add_name_attr
    else
        echo "pf-admin-role attribute verified in PingFederate Admin SSO App configuration..."
    fi
}

function add_pfadmin_attr() {
    # add pf-admin-role to App
    APP_PF_ADMIN_ROLE=$(curl -s --write-out "%{http_code}\n" --location --request POST "$API_LOCATION/environments/$ENV_ID/applications/$WEB_OIDC_APP_ID/attributes" \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    --data-raw '{
        "name": "pf-admin-role",
        "value": "${user.pf-admin-role}",
        "required": true
    }')

    APP_PF_ADMIN_ROLE_RESULT=$(echo $APP_PF_ADMIN_ROLE | sed 's@.*}@@')
    if [[ $APP_PF_ADMIN_ROLE_RESULT == "201" ]]; then
        echo "pf-admin-role attribute added to PingFederate Admin SSO app, beginning content check..."
        check_pfadmin_attr_content
    elif [[ $APP_PF_ADMIN_ROLE_RESULT != "201" ]] && [[ "$add_pfadmin_attr_try" < "$api_call_retry_limit" ]]; then
        add_pfadmin_attr_try=$((add_pfadmin_attr_try+1))
        echo "pf-admin-role attribute NOT added to PingFederate Admin SSO app! Checking attribute existence..."
        check_pfadmin_attr_content
    else
        echo "pf-admin-role attribute NOT added to PingFederate Admin SSO app and attempts to create exceeded!"
        exit 1
    fi
}

add_pfadmin_attr

# # check, create, or set administrator population
# ADMIN_POP_NAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
# --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Administrators Population") | .name')

# if [ "$ADMIN_POP_NAME" != "Administrators Population" ]; then
#     # create administrators population
#     CREATE_ADMIN_POP=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/populations" \
#     --header 'content-type: application/json' \
#     --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
#     --data-raw '{
#       "name" : "Administrators Population",
#       "description" : "Administrators Population"
#     }')

#     ADMIN_POP_NAME_AGAIN=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
#     --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Administrators Population") | .name')
#     if [ "$ADMIN_POP_NAME_AGAIN" != "Administrators Population" ]; then
#         echo "Administrators Population was not successfully created..."
#         exit 1
#     fi
# fi


# ADMIN_POP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
# --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Administrators Population") | .id')

# # create PingFederate admin SSO Account
# CREATE_ADMIN_ACCOUNT=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/users" \
# --header 'content-type: application/vnd.pingidentity.user.import+json' \
# --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
# --data-raw '{
#     "email": "'"pingfederateadmin@$DOMAIN"'",
#     "name": {
#         "given": "Administrator",
#         "family": "User"
#     },
#     "lifecycle": {
#         "status": "ACCOUNT_OK"
#     },
#     "pf-admin-role": "fullAdmin",
#     "population": {
#         "id": "'"$ADMIN_POP_ID"'"
#     },
#     "username": "PingFederateAdmin",
#     "password": {
#         "value": "2FederateM0re!",
#         "forceChange": true
#     }
# }')

# CHECK_ADMIN_ACCOUNT=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/users" \
# --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.users[] | select(.username=="PingFederateAdmin") | .username')

# if [ "$CHECK_ADMIN_ACCOUNT" != "PingFederateAdmin" ]; then
#     echo "PingFederate Admin account not created..."
#     exit 1
# else
#     echo "PingFederate Admin account created..."
# fi

# # get admin user id
# ADMIN_ACCOUNT_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/users" \
# --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.users[] | select(.username=="PingFederateAdmin") | .id')

# # get environment admin role id
# ENV_ADMIN_ROLE_ID=$(curl -s --location --request GET "$API_LOCATION/roles" \
# --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.roles[] | select(.name=="Environment Admin") | .id')

# # assign environment admin role to administrator account
# ASSIGN_ADMIN_USER_ENV_ROLE=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/users/$ADMIN_ACCOUNT_ID/roleAssignments" \
# --header 'Content-Type: application/json' \
# --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
# --data-raw '{
#     "role": {
#         "id": "'"$ENV_ADMIN_ROLE_ID"'"
#     },
#     "scope": {
#         "id": "'"$ENV_ID"'",
#         "type": "ENVIRONMENT"
#     }
# }')

# # verify environment admin role was assigned to administrator account
# CHECK_ADMIN_ROLE=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/users/$ADMIN_ACCOUNT_ID/roleAssignments" \
# --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.roleAssignments[].scope.type')

# if [ "$CHECK_ADMIN_ROLE" != "ENVIRONMENT" ]; then
#     echo "PingFederate Admin environment admin role not assigned..."
#     exit 1
# else
#     echo "PingFederate Admin environment admin role assigned..."
# fi

# # export values into oidc properties tmp file

# # check for existing files
# OIDC_FILE="./oidc.properties.tmp"
# RUN_PROP_FILE="./run.properties.tmp"


# function write_oidc_file_out {

#     OIDC_APP_OAUTH_CONTENT=$(curl -s --location --request GET "https://auth.pingone.com/$ENV_ID/as/.well-known/openid-configuration")

#     APP_CLIENT_ID="$WEB_OIDC_APP_ID"
#     APP_AUTHN_METHOD="client_secret_basic"
#     APP_CLIENT_SECRET=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications/$WEB_OIDC_APP_ID/secret" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '.secret')
#     APP_AUTH_EP=$( echo "$OIDC_APP_OAUTH_CONTENT" | jq -rc '.authorization_endpoint' )
#     APP_TOKEN_EP=$( echo "$OIDC_APP_OAUTH_CONTENT" | jq -rc '.token_endpoint' )
#     APP_USERINFO_EP=$( echo "$OIDC_APP_OAUTH_CONTENT" | jq -rc '.userinfo_endpoint' )
#     APP_SO_EP=$( echo "$OIDC_APP_OAUTH_CONTENT" | jq -rc '.end_session_endpoint' )
#     APP_ISSUER=$( echo "$OIDC_APP_OAUTH_CONTENT" | jq -rc '.issuer' )
#     APP_SCOPES=$( echo "$OIDC_APP_OAUTH_CONTENT" | jq -rc '.scopes_supported' | sed -e 's/\[//g' -e 's/\"/ /g' -e 's/ //g' -e 's/\,/ /g' -e 's/\]//g')
#     APP_USERNAME_ATTRIBUTE=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications/$WEB_OIDC_APP_ID/attributes" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.attributes[] | select(.value=="${user.name.formatted}") | .name')
#     APP_ATTR_NAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications/$WEB_OIDC_APP_ID/attributes" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.attributes[] | select (.name=="pf-admin-role") | .name' )
#     APP_ROLE_NAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/users/$ADMIN_ACCOUNT_ID?expand=population" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '."pf-admin-role"')

#     echo "client.id=$APP_CLIENT_ID" >> $OIDC_FILE
#     echo "client.authn.method=$APP_AUTHN_METHOD" >> $OIDC_FILE
#     # the client secret needs to be run against obfuscate script in PingFederate
#     echo "client.secret=$APP_CLIENT_SECRET" >> $OIDC_FILE
#     echo "authorization.endpoint=$APP_AUTH_EP" >> $OIDC_FILE
#     echo "token.endpoint=$APP_TOKEN_EP" >> $OIDC_FILE
#     echo "user.info.endpoint=$APP_USERINFO_EP" >> $OIDC_FILE
#     echo "end.session.endpoint=$APP_SO_EP" >> $OIDC_FILE
#     echo "issuer=$APP_ISSUER" >> $OIDC_FILE
#     echo "scopes=$APP_SCOPES" >> $OIDC_FILE
#     echo "username.attribute.name=$APP_USERNAME_ATTRIBUTE" >> $OIDC_FILE
#     echo "role.attribute.name=$APP_ATTR_NAME" >> $OIDC_FILE
#     echo "role.admin=$APP_ROLE_NAME" >> $OIDC_FILE
#     echo "role.cryptoManager=$APP_ROLE_NAME" >> $OIDC_FILE
#     echo "role.userAdmin=$APP_ROLE_NAME" >> $OIDC_FILE
#     echo "role.expressionAdmin=eadmin" >> $OIDC_FILE
# }

# # handles existing oidc file, or creates said file
# if [ -f "$OIDC_FILE" ]; then
#     echo "Existing oidc file present, taking care of that..."
#     mv $OIDC_FILE "$OIDC_FILE.old"
#     echo -n "" > "$OIDC_FILE.old"
#     echo "Existing oidc file named to $OIDC_FILE.old"
#     write_oidc_file_out
# else
#     echo "No existing oidc file, creating now..."
#     write_oidc_file_out
# fi

# function write_prop_file_out {
#     # export values into run properties tmp file

#     PF_ADMIN_HOSTNAME="$PINGFED_BASE_URL"
#     OIDC_APP_NAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select (.name=="PingFederate Admin SSO") | .name')
#     CONSOLE_ENV_NAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '. | select(.name="Administrators") | .id')

#     echo "pf.admin.hostname=$PF_ADMIN_HOSTNAME" >> $RUN_PROP_FILE
#     echo "pf.console.title=$OIDC_APP_NAME" >> $RUN_PROP_FILE
#     echo "pf.console.environment=$CONSOLE_ENV_NAME" >> $RUN_PROP_FILE
#     echo "pf.console.authentication=OIDC" >> $RUN_PROP_FILE
# }

# # handles existing properties file, or creates said file
# if [ -f "$RUN_PROP_FILE" ]; then
#     echo "Existing properties file present, taking care of that..."
#     mv $RUN_PROP_FILE "$RUN_PROP_FILE.old"
#     echo -n "" > "$RUN_PROP_FILE.old"
#     echo "Existing properties file named to $RUN_PROP_FILE.old"
#     write_prop_file_out
# else
#     echo "No existing properties file, creating now..."
#     write_prop_file_out
# fi