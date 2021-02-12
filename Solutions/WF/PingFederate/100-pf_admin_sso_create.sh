#!/bin/bash

# configure PingOne for PingFed Admin SSO

#Variables needed to be passed for this script:
# API_LOCATION
# ENV_ID
# WORKER_APP_ACCESS_TOKEN
# PINGFED_BASE_URL
# DOMAIN
# ENV_NAME => this needs to be the Name of the desired environment

# get schema ID needed for creating attribute
USER_SCHEMA_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/schemas" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.schemas[].id'
)

# check to make sure PingFed Admin Role was created
CHECK_ADMIN_ATTRIBUTE=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/schemas/$USER_SCHEMA_ID/attributes" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.attributes[] | select (.name=="pf-admin-roles") | .enabled')

if [ "$CHECK_ADMIN_ATTRIBUTE" != "true" ]; then
    echo "PingFederate Admin attribute not created, creating now..."
    # create PingFed Admin Role attribute
    PF_ADMIN_ATTRIBUTE=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/schemas/$USER_SCHEMA_ID/attributes" \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    --data-raw '{
    "description": " ",
    "displayName": "PingFed Admin Roles",
    "enabled": true,
    "name": "pf-admin-roles",
    "required": false,
    "type": "STRING",
    "unique": false
    }')

    CHECK_ADMIN_ATTRIBUTE_AGAIN=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/schemas/$USER_SCHEMA_ID/attributes" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.attributes[] | select (.name=="pf-admin-roles") | .enabled')
    if [ "$CHECK_ADMIN_ATTRIBUTE_AGAIN" != "true" ]; then
        echo "PingFederate Admin attribute not created..."
        exit 1
    else
        echo "PingFederate Admin attribute created..."
    fi
else
    echo "PingFederate Admin attribute created..."
fi

# add Web OIDC App
WEB_OIDC_APP=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/applications" \
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

# check to make sure Web OIDC App was created
CHECK_WEB_OIDC_APP=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select (.name=="PingFederate Admin SSO") | .enabled')

if [ "$CHECK_WEB_OIDC_APP" != "true" ]; then
    echo "PingFederate Admin SSO App not created..."
    exit 1
else
    echo "PingFederate Admin SSO App created..."
fi

# get Web OIDC App ID to be used in attribute mapping
WEB_OIDC_APP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select (.name=="PingFederate Admin SSO") | .id')

# add username attribute to App
APP_USERNAME_ID=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/applications/$WEB_OIDC_APP_ID/attributes" \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '{
    "name": "name",
    "value": "${user.name.formatted}",
    "required": true
}')

# add id attribute to App
APP_NAME_ID=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/applications/$WEB_OIDC_APP_ID/attributes" \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '{
    "name": "sub",
    "value": "${user.id}",
    "required": true
}')

# add pf-admin-roles to App
APP_PF_ADMIN_ROLE=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/applications/$WEB_OIDC_APP_ID/attributes" \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '{
    "name": "pf-admin-roles",
    "value": "${user.pf-admin-roles}",
    "required": true
}')

# verify pf-admin-role attribute
CHECK_WEB_OIDC_APP_ATTR=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications/$WEB_OIDC_APP_ID/attributes" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.attributes[] | select (.name=="pf-admin-roles") | .name')

if [ "$CHECK_WEB_OIDC_APP_ATTR" != "pf-admin-roles" ]; then
    echo "PingFederate Admin SSO App custom attribute not created..."
    exit 1
else
    echo "PingFederate Admin SSO App custom attribute created..."
fi

# check, create, or set administrator population
ADMIN_POP_NAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Administrators Population") | .name')

if [ "$ADMIN_POP_NAME" != "Administrators Population"]; then
    # create sample employee population
    CREATE_ADMIN_POP=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/populations" \
    --header 'content-type: application/json' \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    --data-raw '{
      "name" : "Administrators Population",
      "description" : "Administrators Population"
    }')

    ADMIN_POP_NAME_AGAIN=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Administrators Population") | .name')
    if [ "$ADMIN_POP_NAME_AGAIN" != "Administrators Population"]; then
        echo "Administrators Population was not successfully created..."
        exit 1
    fi
fi


ADMIN_POP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Administrators Population") | .id')

# create PingFederate admin SSO Account
CREATE_ADMIN_ACCOUNT=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/users" \
--header 'content-type: application/vnd.pingidentity.user.import+json' \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '{
    "email": "'"administrator@$DOMAIN"'",
    "name": {
        "given": "Administrator",
        "family": "User"
    },
    "lifecycle": {
        "status": "ACCOUNT_OK"
    },
    "pf-admin-roles": "fullAdmin",
    "population": {
        "id": "'"$ADMIN_POP_ID"'"
    },
    "username": "PingFederateAdmin",
    "password": {
        "value": "2FederateM0re!",
        "forceChange": true
    }
}')

CHECK_ADMIN_ACCOUNT=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/users" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.users[] | select(.username=="PingFederateAdmin") | .username')

if [ "$CHECK_ADMIN_ACCOUNT" != "PingFederateAdmin" ]; then
    echo "PingFederate Admin account not created..."
    exit 1
else
    echo "PingFederate Admin account created..."
fi

# get admin user id
ADMIN_ACCOUNT_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/users" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.users[] | select(.username=="PingFederateAdmin") | .id')

# get environment admin role id
ENV_ADMIN_ROLE_ID=$(curl -s --location --request GET "$API_LOCATION/roles" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.roles[] | select(.name=="Environment Admin") | .id')

# assign environment admin role to administrator account
ASSIGN_ADMIN_USER_ENV_ROLE=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/users/$ADMIN_ACCOUNT_ID/roleAssignments" \
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

# verify environment admin role was assigned to administrator account
CHECK_ADMIN_ROLE=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/users/$ADMIN_ACCOUNT_ID/roleAssignments" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.roleAssignments[].scope.type')

if [ "$CHECK_ADMIN_ROLE" != "ENVIRONMENT" ]; then
    echo "PingFederate Admin environment admin role not created..."
    exit 1
else
    echo "PingFederate Admin environment admin role created..."
fi

# export values into oidc properties tmp file

# check for existing files
OIDC_FILE="./oidc.properties.tmp"
RUN_PROP_FILE="./run.properties.tmp"


function write_oidc_file_out {

    OIDC_APP_OAUTH_CONTENT=$(curl -s --location --request GET "https://auth.pingone.com/$ENV_ID/as/.well-known/openid-configuration")

    APP_CLIENT_ID="$WEB_OIDC_APP_ID"
    APP_AUTHN_METHOD="client_secret_basic"
    APP_CLIENT_SECRET=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications/$WEB_OIDC_APP_ID/secret" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '.secret')
    APP_AUTH_EP=$( echo "$OIDC_APP_OAUTH_CONTENT" | jq -rc '.authorization_endpoint' )
    APP_TOKEN_EP=$( echo "$OIDC_APP_OAUTH_CONTENT" | jq -rc '.token_endpoint' )
    APP_USERINFO_EP=$( echo "$OIDC_APP_OAUTH_CONTENT" | jq -rc '.userinfo_endpoint' )
    APP_SO_EP=$( echo "$OIDC_APP_OAUTH_CONTENT" | jq -rc '.end_session_endpoint' )
    APP_ISSUER=$( echo "$OIDC_APP_OAUTH_CONTENT" | jq -rc '.issuer' )
    APP_SCOPES=$( echo "$OIDC_APP_OAUTH_CONTENT" | jq -rc '.scopes_supported' | sed -e 's/\[//g' -e 's/\"/ /g' -e 's/ //g' -e 's/\,/ /g' -e 's/\]//g')
    APP_USERNAME_ATTRIBUTE=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications/$WEB_OIDC_APP_ID/attributes" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.attributes[] | select(.value=="${user.name.formatted}") | .name')
    APP_ATTR_NAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications/$WEB_OIDC_APP_ID/attributes" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.attributes[] | select (.name=="pf-admin-roles") | .name' )
    APP_ROLE_NAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/users/$ADMIN_ACCOUNT_ID?expand=population" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '."pf-admin-roles"')

    echo "client.id=$APP_CLIENT_ID" >> $OIDC_FILE
    echo "client.authn.method=$APP_AUTHN_METHOD" >> $OIDC_FILE
    # the client secret needs to be run against obfuscate script in PingFederate
    echo "client.secret=$APP_CLIENT_SECRET" >> $OIDC_FILE
    echo "authorization.endpoint=$APP_AUTH_EP" >> $OIDC_FILE
    echo "token.endpoint=$APP_TOKEN_EP" >> $OIDC_FILE
    echo "user.info.endpoint=$APP_USERINFO_EP" >> $OIDC_FILE
    echo "end.session.endpoint=$APP_SO_EP" >> $OIDC_FILE
    echo "issuer=$APP_ISSUER" >> $OIDC_FILE
    echo "scopes=$APP_SCOPES" >> $OIDC_FILE
    echo "username.attribute.name=$APP_USERNAME_ATTRIBUTE" >> $OIDC_FILE
    echo "role.attribute.name=$APP_ATTR_NAME" >> $OIDC_FILE
    echo "role.admin=$APP_ROLE_NAME" >> $OIDC_FILE
    echo "role.cryptoManager=$APP_ROLE_NAME" >> $OIDC_FILE
    echo "role.userAdmin=$APP_ROLE_NAME" >> $OIDC_FILE
    echo "role.expressionAdmin=eadmin" >> $OIDC_FILE
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

function write_prop_file_out {
    # export values into run properties tmp file

    PF_ADMIN_HOSTNAME="$PINGFED_BASE_URL"
    OIDC_APP_NAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select (.name=="PingFederate Admin SSO") | .name')
    CONSOLE_ENV_NAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '. | select(.name="Administrators") | .id')

    echo "pf.admin.hostname=$PF_ADMIN_HOSTNAME" >> $RUN_PROP_FILE
    echo "pf.console.title=$OIDC_APP_NAME" >> $RUN_PROP_FILE
    echo "pf.console.environment=$CONSOLE_ENV_NAME" >> $RUN_PROP_FILE
    echo "pf.console.authentication=OIDC" >> $RUN_PROP_FILE
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