#!/bin/bash

# configure PingOne Sample SAML Apps for CIAM
#Variables needed to be passed for this script:
# API_LOCATION
# ENV_ID
# WORKER_APP_ACCESS_TOKEN

# set global api call retry limit - this can be set to desired amount, default is 2
api_call_retry_limit=2

# get signing key to assign to all applications
SIGNING_KEY_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/keys" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.keys[] | select(.usageType=="SIGNING") | .id')

################## create Demo App - Self-Service Registration ##################
ssr_app_try=0

# verify application content to verify app creation
function check_ssr_app_content() {
    CHECK_SSR_APP_CONTENT=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select(.name=="Demo App - Self-Service Registration") | .name')

    if [ "$CHECK_SSR_APP_CONTENT" == "Demo App - Self-Service Registration" ]; then
        echo "Self-Service Registration app exists and verified content..."
    else
        echo "Unable to locate Self-Service Registration app, or application does not exist!"
        ssr_checks_remaining=$((api_call_retry_limit-ssr_app_try))
        echo "Attempting to create Self-Service Registration app again. $ssr_checks_remaining remaining after next creation attempt(s)..."
        create_ssr_app
    fi
}

function check_ssr_app_creation() {
    # checks app created, as well as verify expected app name to ensure creation
    CREATE_SSR_APP_RESULT=$(echo $CREATE_SSR_APP | sed 's@.*}@@')
    if [ $CREATE_SSR_APP_RESULT == "201" ]; then
        echo "Self-Service Registration demo app added, beginning content check..."
        check_ssr_app_content
    elif [[ $CREATE_SSR_APP_RESULT != "201" ]] && [[ "$ssr_app_try" < "$api_call_retry_limit" ]]; then
        ssr_app_try=$((ssr_app_try+1))
        echo "Self-Service Registration demo app NOT added! Checking app existence..."
        check_ssr_app_content
    else
        echo "Self-Service Registration demo app does NOT exist and attempts to create exceeded!"
        exit 1
    fi
}

function create_ssr_app() {
    CREATE_SSR_APP=$(curl -s --write-out "%{http_code}\n" --location --request POST "$API_LOCATION/environments/$ENV_ID/applications" \
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

    # call app creation function to do checks
    check_ssr_app_creation
}

# call create self-service registration app function above
create_ssr_app


################## create Demo App - Passwordless Login SMS Only ##################
sms_app_try=0

# verify application content to verify app creation
function check_sms_app_content() {
    CHECK_SMS_APP_CONTENT=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select(.name=="Demo App - Passwordless Login SMS Only") | .name')

    if [ "$CHECK_SMS_APP_CONTENT" == "Demo App - Passwordless Login SMS Only" ]; then
        echo "Passwordless Login SMS Only app exists and verified content..."
    else
        echo "Unable to locate Passwordless Login SMS Only app, or application does not exist!"
        sms_checks_remaining=$((api_call_retry_limit-sms_app_try))
        echo "Attempting to create Passwordless Login SMS Only app again. $sms_checks_remaining remaining after next creation attempt(s)"
        create_sms_app
    fi
}

# checks app created, as well as verify expected app name to ensure creation
function check_sms_app_creation() {
    CREATE_SMS_APP_RESULT=$(echo $CREATE_SMS_APP | sed 's@.*}@@')
    if [ $CREATE_SMS_APP_RESULT == "201" ] ; then
        echo "Passwordless Login SMS Only app added, beginning content check..."
        check_sms_app_content
    elif [[ $CREATE_SMS_APP_RESULT != "201" ]] && [[ "$sms_app_try" < "$api_call_retry_limit" ]]; then
        sms_app_try=$((sms_app_try+1))
        echo "Passwordless Login SMS Only app NOT added! Checking app existence..."
        check_sms_app_content
    else
        echo "Passwordless Login SMS Only app does NOT exist and attempts to create exceeded!"
        exit 1
    fi
}

function create_sms_app() {
    CREATE_SMS_APP=$(curl -s --write-out "%{http_code}\n" --location --request POST "$API_LOCATION/environments/$ENV_ID/applications" \
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

    # call app creation function to do checks
    check_sms_app_creation
}
# call create sms passwordless app function above
create_sms_app

################## create Demo App - Passwordless Login Any Method ##################
pwdless_app_try=0

# verify application content to verify app creation
function check_pwdless_app_content() {
    CHECK_PWDLESS_APP_CONTENT=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select(.name=="Demo App - Passwordless Login Any Method") | .name')

    if [ "$CHECK_PWDLESS_APP_CONTENT" == "Demo App - Passwordless Login Any Method" ]; then
        echo "Passwordless Login Any Method app exists and verified content..."
    else
        echo "Unable to locate Passwordless Login Any Method app, or application does not exist!"
        pwdless_checks_remaining=$((api_call_retry_limit-pwdless_app_try))
        echo "Attempting to create Passwordless Login SMS Only app again. $pwdless_checks_remaining remaining after next creation attempt(s)"
        create_pwdless_app
    fi
}

function check_pwdless_app_creation() {
    # checks app created, as well as verify expected app name to ensure creation
    CREATE_PWDLESS_APP_RESULT=$(echo $CREATE_PWDLESS_APP | sed 's@.*}@@')
    if [ $CREATE_PWDLESS_APP_RESULT == "201" ] ; then
        echo "Passwordless Login Any Method app added, beginning content check..."
        check_pwdless_app_content
    elif [[ $CREATE_PWDLESS_APP_RESULT != "201" ]] && [[ "$pwdless_app_try" < "$api_call_retry_limit" ]]; then
        pwdless_app_try=$((pwdless_app_try+1))
        echo "Passwordless Login Any Method app NOT added! Checking app existence..."
        check_pwdless_app_content
    else
        echo "Passwordless Login Any Method app does NOT exist and attempts to create exceeded!"
        exit 1
    fi
}

function create_pwdless_app() {
    CREATE_PWDLESS_APP=$(curl -s --write-out "%{http_code}\n" --location --request POST "$API_LOCATION/environments/$ENV_ID/applications" \
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

    # call app creation function above to do checks
    check_pwdless_app_creation
}
# call create passwordless app function above
create_pwdless_app