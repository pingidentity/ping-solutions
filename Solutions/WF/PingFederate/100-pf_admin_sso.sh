#!/bin/bash

# configure PingOne for PingFed Admin SSO

#Variables needed to be passed for this script:
# API_LOCATION
# ENV_ID
# WORKER_APP_ACCESS_TOKEN
# PINGFED_BASE_URL
# DOMAIN

API_LOCATION="https://api.pingone.com/v1"
ENV_ID="df43976d-9c35-4080-81d1-570ef5563007"
CLIENT_ID="94b0fa73-812d-439a-ac5d-ebd4467cade4"
CLIENT_SECRET="4rpPVdx5VRiaCw7giGIumNq~iuy-APeQDD5qswbM~aSHpYnoGmCMIYtqAj5ivL_L"
PINGFED_BASE_URL="https://example.com"
DOMAIN="example.com"

WORKER_APP_ACCESS_TOKEN=$(curl -s -u $CLIENT_ID:$CLIENT_SECRET \
--location --request POST "https://auth.pingone.com/$ENV_ID/as/token" \
--header "Content-Type: application/x-www-form-urlencoded" \
--data-raw 'grant_type=client_credentials' \
| jq -r '.access_token')

# get schema ID needed for creating attribute
USER_SCHEMA_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/schemas" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.schemas[].id'
)

# create PingFed Admin Role attribute
PF_ADMIN_ATTRIBUTE=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/schemas/$USER_SCHEMA_ID/attributes" \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '{
    "description": " ",
    "displayName": "PingFederate Admin Role",
    "enabled": true,
    "name": "pf-admin-role",
    "required": false,
    "type": "STRING",
    "unique": false
}')

# check to make sure PingFed Admin Role was created
CHECK_ADMIN_ATTRIBUTE=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/schemas/$USER_SCHEMA_ID/attributes" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.attributes[] | select (.name=="pf-admin-role") | .enabled')

if [ "$CHECK_ADMIN_ATTRIBUTE" != "true" ]; then
    echo "PingFederate Admin attribute not created..."
    exit 1
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

# add pf-admin-role to App
APP_PF_ADMIN_ROLE=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/applications/$WEB_OIDC_APP_ID/attributes" \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '{
    "name": "pf-admin-role",
    "value": "${user.pf-admin-role}",
    "required": true
}')

# verify pf-admin-role attribute
CHECK_WEB_OIDC_APP_ATTR=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications/$WEB_OIDC_APP_ID/attributes" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.attributes[] | select (.name=="pf-admin-role") | .name')

if [ "$CHECK_WEB_OIDC_APP_ATTR" != "pf-admin-role" ]; then
    echo "PingFederate Admin SSO App custom attribute not created..."
    exit 1
else
    echo "PingFederate Admin SSO App custom attribute created..."
fi

# get current Administrators Population
ADMIN_POP=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Administrators Population") | .id')

# create PingFederate Admin SSO Account
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
    "pf-admin-role": "fullAdmin",
    "population": {
        "id": "'"$ADMIN_POP"'"
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

export values into oidc properties tmp file
OIDC_APP_OAUTH_CONTENT=$(curl -s --location --request GET "https://auth.pingone.com/$ENV_ID/as/.well-known/openid-configuration")

APP_CLIENT_ID="$WEB_OIDC_APP_ID"
APP_AUTHN_METHOD="client_secret_basic"
APP_CLIENT_SECRET=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications/$WEB_OIDC_APP_ID/secret" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '.secret')
APP_AUTH_EP=$( echo "$OIDC_APP_OAUTH_CONTENT" | jq -rc '.authorization_endpoint' )
APP_TOKEN_EP=$( echo "$OIDC_APP_OAUTH_CONTENT" | jq -rc '.token_endpoint' )
APP_USERINFO_EP=$( echo "$OIDC_APP_OAUTH_CONTENT" | jq -rc '.userinfo_endpoint' )
APP_SO_EP=$( echo "$OIDC_APP_OAUTH_CONTENT" | jq -rc '.end_session_endpoint' )
APP_ISSUER=$( echo "$OIDC_APP_OAUTH_CONTENT" | jq -rc '.issuer' )
APP_SCOPES=$( echo "$OIDC_APP_OAUTH_CONTENT" | jq -rc '.scopes_supported' | sed -e 's/\[//g' -e 's/\"/ /g' -e 's/\ //g' -e 's/\,/ /g' -e 's/\]//g')
APP_USERNAME_ATTRIBUTE=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications/$WEB_OIDC_APP_ID/attributes" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.attributes[] | select(.value=="${user.name.formatted}") | .name')
APP_ATTR_NAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications/$WEB_OIDC_APP_ID/attributes" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.attributes[] | select (.name=="pf-admin-role") | .name' )
APP_ROLE_NAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/users/$ADMIN_ACCOUNT_ID?expand=population" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '."pf-admin-role"')

echo "client.id=$APP_CLIENT_ID" >> oidc.properties.tmp
echo "client.authn.method=$APP_AUTHN_METHOD" >> oidc.properties.tmp
# the client secret needs to be run against obfuscate script in PingFederate
echo "client.secret=$APP_CLIENT_SECRET" >> oidc.properties.tmp
echo "authorization.endpoint=$APP_AUTH_EP" >> oidc.properties.tmp
echo "token.endpoint=$APP_TOKEN_EP" >> oidc.properties.tmp
echo "user.info.endpoint=$APP_USERINFO_EP" >> oidc.properties.tmp
echo "end.session.endpoint=$APP_SO_EP" >> oidc.properties.tmp
echo "issuer=$APP_ISSUER" >> oidc.properties.tmp
echo "scopes=$APP_SCOPES" >> oidc.properties.tmp
echo "username.attribute.name=$APP_USERNAME_ATTRIBUTE" >> oidc.properties.tmp
echo "role.attribute.name=$APP_ATTR_NAME" >> oidc.properties.tmp
echo "role.admin=$APP_ROLE_NAME" >> oidc.properties.tmp
echo "role.cryptoManager=$APP_ROLE_NAME" >> oidc.properties.tmp
echo "role.userAdmin=$APP_ROLE_NAME" >> oidc.properties.tmp