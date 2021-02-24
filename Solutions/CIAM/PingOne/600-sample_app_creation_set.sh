#!/bin/bash

# configure PingOne Sample SAML Apps for CIAM
#Variables needed to be passed for this script:
#API_LOCATION
#ENV_ID
#WORKER_APP_ACCESS_TOKEN

SIGNING_KEY_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/keys" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.keys[] | select(.usageType=="SIGNING") | .id')

# create Demo App - Self-Service Registration
CREATE_SAMPLE_APP1=$(curl -s --write-out "%{http_code}\n" --location --request POST "$API_LOCATION/environments/$ENV_ID/applications" \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '{
    "name": "Demo App - Self-Service Registration",
    "description": "This is a sample app used to demonstrate a Self-Service Registration policy with an Idp-Initiated SAML connection to a public SP API-Based application. You can use the PingIdentity SAML Decoder tool to copy and paste the SAMLResponse from the httpbin value. https://developer.pingidentity.com/en/tools/saml-decoder.html",
    "enabled": true,
    "type": "WEB_APP",
    "protocol": "SAML",
    "spEntityId": "demo_app_1",
    "responseSigned": false,
    "sloBinding": "HTTP_POST",
    "acsUrls": [
    "https://httpbin.org/anything"
    ],
    "assertionDuration": 60,
    "assertionSigned": true,
    "idpSigning": {
        "key": {
            "id": "'"$SIGNING_KEY_ID"'"
        },
        "algorithm": "SHA256withRSA"
    }
}')

# checks app created, as well as verify expected app name to ensure creation
CREATE_SAMPLE_APP1_RESULT=$(echo $CREATE_SAMPLE_APP1 | sed 's@.*}@@')
if [ $CREATE_SAMPLE_APP1_RESULT == "201" ] ; then

    CHECK_SAMPLE_APP1_CONTENT=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select(.name=="Demo App - Self-Service Registration") | .name')

    if [ "$CHECK_SAMPLE_APP1_CONTENT" == "Demo App - Self-Service Registration" ]; then
        echo "Demo App - Self-Service Registration app added and verified content..."
    else
        echo "Demo App - Self-Service Registration app added, however unable to verified content!"
    fi
else
    echo "Demo App - Self-Service Registration app NOT added!"
    exit 1
fi

# create Demo App - Passwordless Login SMS Only
CREATE_SAMPLE_APP2=$(curl -s --write-out "%{http_code}\n" --location --request POST "$API_LOCATION/environments/$ENV_ID/applications" \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '{
    "name": "Demo App - Passwordless Login SMS Only",
    "description": "This is a sample app used to demonstrate a Passwordless Login SMS Only policy with an Idp-Initiated SAML connection to a public SP API-Based application. You can use the PingIdentity SAML Decoder tool to copy and paste the SAMLResponse from the httpbin value. https://developer.pingidentity.com/en/tools/saml-decoder.html",
    "enabled": true,
    "type": "WEB_APP",
    "protocol": "SAML",
    "spEntityId": "demo_app_2",
    "responseSigned": false,
    "sloBinding": "HTTP_POST",
    "acsUrls": [
    "https://httpbin.org/anything"
    ],
    "assertionDuration": 60,
    "assertionSigned": true,
    "idpSigning": {
        "key": {
            "id": "'"$SIGNING_KEY_ID"'"
        },
        "algorithm": "SHA256withRSA"
    }
}')

# checks app created, as well as verify expected app name to ensure creation
CREATE_SAMPLE_APP2_RESULT=$(echo $CREATE_SAMPLE_APP2 | sed 's@.*}@@')
if [ $CREATE_SAMPLE_APP2_RESULT == "201" ] ; then

    CHECK_SAMPLE_APP2_CONTENT=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select(.name=="Demo App - Passwordless Login SMS Only") | .name')

    if [ "$CHECK_SAMPLE_APP2_CONTENT" == "Demo App - Passwordless Login SMS Only" ]; then
        echo "Passwordless Login SMS Only app added and verified content..."
    else
        echo "Passwordless Login SMS Only app added, however unable to verified content!"
    fi
else
    echo "Passwordless Login SMS Only app NOT added!"
    exit 1
fi

# create Demo App - Passwordless Login Any Method
CREATE_SAMPLE_APP3=$(curl -s --write-out "%{http_code}\n" --location --request POST "$API_LOCATION/environments/$ENV_ID/applications" \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '{
    "name": "Demo App - Passwordless Login Any Method",
    "description": "This is a sample app used to demonstrate a Passwordless Login Any Method with an Idp-Initiated SAML connection to a public SP API-Based application. You can use the PingIdentity SAML Decoder tool to copy and paste the SAMLResponse from the httpbin value. https://developer.pingidentity.com/en/tools/saml-decoder.html",
    "enabled": true,
    "type": "WEB_APP",
    "protocol": "SAML",
    "spEntityId": "demo_app_3",
    "responseSigned": false,
    "sloBinding": "HTTP_POST",
    "acsUrls": [
    "https://httpbin.org/anything"
    ],
    "assertionDuration": 60,
    "assertionSigned": true,
    "idpSigning": {
        "key": {
            "id": "'"$SIGNING_KEY_ID"'"
        },
        "algorithm": "SHA256withRSA"
    }
}')

# checks app created, as well as verify expected app name to ensure creation
CREATE_SAMPLE_APP3_RESULT=$(echo $CREATE_SAMPLE_APP3 | sed 's@.*}@@')
if [ $CREATE_SAMPLE_APP3_RESULT == "201" ] ; then

    CHECK_SAMPLE_APP3_CONTENT=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select(.name=="Demo App - Passwordless Login Any Method") | .name')

    if [ "$CHECK_SAMPLE_APP3_CONTENT" == "Demo App - Passwordless Login Any Method" ]; then
        echo "Demo App - Passwordless Login Any Method app added and verified content..."
    else
        echo "Demo App - Passwordless Login Any Method app added, however unable to verified content!"
    fi
else
    echo "Demo App - Passwordless Login Any Method NOT added!"
    exit 1
fi
