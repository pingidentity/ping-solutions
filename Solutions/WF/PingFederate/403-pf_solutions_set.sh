#!/bin/bash

# Create Active Directory in PingFederate

# Variables needed to pass for this script:
# PINGFED_BASE_URL
# PF_USERNAME
# PF_PASSWORD

echo "###### Beginning of 403-pf_solutions_set.sh ######"

####################################### Verify Active Directory Data store creation #######################################

api_call_retry_limit=1
ds_try=0

PF_CRED=$(echo -n $PF_USERNAME:$PF_PASSWORD | base64)

function verify_ds() {
    # Checks for Datastore ID to verify if Datastore was added.
    if [[ "$DS_ID" == *"LDAP-"* ]]; then
        echo "Added Demo LDAP Data Store..."
    elif ([[ -z ${DS_ID+x} ]] || [[ "$DS_ID" == "null" ]]) && [[ "$ds_try" -lt "$api_call_retry_limit" ]]; then
        check_ds
        if [[ "$CHECK_DS_NAME" == "Demo LDAP Data Store" ]]; then
            echo "Data Store with the same name already exists..."
        else
            ds_tries_left=$((api_call_retry_limit-ds_try))
            echo "Demo LDAP Data Store not added, retrying $ds_tries_left more time(s)..."
            ds_try=$((ds_try+1))
            create_ds
        fi
    else
        echo "Demo LDAP Data Store not added and exceeded try limit!"
        exit 1
    fi
}
function check_ds() {
    CHECK_DS_NAME=$(curl -s --insecure --location --request GET "https://$PINGFED_BASE_URL/pf-admin-api/v1/dataStores" \
    --header 'X-XSRF-Header: PASS' \
    --header "Authorization: Basic $PF_CRED" | jq -rc '.items[] | select(.name=="Demo LDAP Data Store") | .name')
}
####################################### Add Active Directory Data Store #######################################

function create_ds() {
    DS_ID=$(curl -s --insecure --location --request POST "https://$PINGFED_BASE_URL/pf-admin-api/v1/dataStores" \
        --header "X-XSRF-Header: PASS" \
        --header 'X-BypassExternalValidation: true' \
        --header "Authorization: Basic $PF_CRED" \
        --header "Content-Type: application/json" \
        --data-raw '{
        "type": "LDAP",
        "name": "Demo LDAP Data Store",
        "useSsl":false,
        "hostnames" : ["0.0.0.0"],
        "userDN": "example_ldap_username",
        "password": "example_ldap_password"
        }'| jq -rc '.id')
    verify_ds
}
create_ds

####################################### Verify LDAP PCV creation #######################################
pcv_try=0

function verify_pcv() {
    # Checks for Password Credential Validator ID to verify if PCV is created.
    if [[ $PCV_ID =~ ^[A-Za-z0-9]{1,33}$ ]] && [[ $PCV_ID != null ]]; then
        echo "Created LDAP PCV..."
    elif ([[ -z ${PCV_ID+x} ]] || [[ "$PCV_ID" == "null" ]]) && [[ "$pcv_try" -lt "$api_call_retry_limit" ]]; then
        check_pcv
        if [[ "$CHECK_PCV_NAME" == "DemoPCV" ]]; then
            echo "LDAP PVC with the same name already exists..."
        else
            pcv_tries_left=$((api_call_retry_limit-pcv_try))
            echo "LDAP PCV not created, retrying $pcv_tries_left more time(s)..."
            pcv_try=$((pcv_try+1))
            create_pcv
        fi
    else
        echo "LDAP PCV not created and exceeded try limit!"
        exit 1
    fi
}

function check_pcv() {
    CHECK_PCV_NAME=$(curl -s --insecure --location --request GET "https://$PINGFED_BASE_URL/pf-admin-api/v1/passwordCredentialValidators" \
    --header 'X-XSRF-Header: PASS' \
    --header "Authorization: Basic $PF_CRED" | jq -rc '.items[] | select(.name=="DemoPCV") | .name')
}

####################################### Create LDAP Password Credential Validator #######################################

function create_pcv() {
PCV_ID=$(curl -s --insecure --location --request POST "https://$PINGFED_BASE_URL/pf-admin-api/v1/passwordCredentialValidators" \
        --header 'X-XSRF-Header: PASS' \
        --header 'X-BypassExternalValidation: true' \
        --header "Authorization: Basic $PF_CRED" \
        --header 'Content-Type: application/json' \
        --data-raw '{
        "id": "DemoID",
        "name": "DemoPCV",
        "pluginDescriptorRef": {
            "id": "org.sourceid.saml20.domain.LDAPUsernamePasswordCredentialValidator",
            "location": "'"https://$PINGFED_BASE_URL/pf-admin-api/v1/passwordCredentialValidators/descriptors/org.sourceid.saml20.domain.LDAPUsernamePasswordCredentialValidator"'"
        },
        "configuration": {
            "fields": [
            {
                "name": "LDAP Datastore",
                "value": "'"$DS_ID"'"
            },
            {
                "name": "Search Base",
                "value": "dc=example,dc=com"
            },
            {
                "name": "Search Filter",
                "value": "sAMAccountName=${username}"
            }
            ]
        }
        }' | jq -rc '.id')
        verify_pcv
}
create_pcv

####################################### Verify Notification Publisher creation #######################################
np_try=0

function verify_notification_publisher {
    # Checks for Notification Publisher ID to verify if Notification Publisher is created.
    if [[ $NP_ID =~ ^[A-Za-z0-9]{1,33}$ ]] && [[ $NP_ID != null ]]; then
        echo "Created Notification Publisher..."
    elif ([[ -z ${NP_ID+x} ]] || [[ "$NP_ID" == "null" ]]) && [[ "$np_try" -lt "$api_call_retry_limit" ]]; then
        check_notification_publisher
        if [[ "$CHECK_NP_NAME" == "DemoSMTP" ]]; then
            echo "Notificiation Publisher with the same name already exists..."
        else
        np_tries_left=$((api_call_retry_limit-np_try))
        echo "Notification Publisher not created, retrying $np_tries_left more time(s)..."
        np_try=$((np_try_try+1))
        create_notification_publisher
        fi
    else
        echo "Notification Publisher not created and exceeded try limit!"
        exit 1
    fi
}

function check_notification_publisher() {
    CHECK_NP_NAME=$(curl -s --insecure --location --request GET "https://$PINGFED_BASE_URL/pf-admin-api/v1/notificationPublishers" \
    --header 'X-XSRF-Header: PASS' \
    --header "Authorization: Basic $PF_CRED" | jq -rc '.items[] | select(.name=="DemoSMTP") | .name')
}

######################################## Create Notiifcation Publisher #######################################

function create_notification_publisher {
NP_ID=$(curl -s --insecure --location --request POST "https://$PINGFED_BASE_URL/pf-admin-api/v1/notificationPublishers" \
    --header 'X-XSRF-Header: PASS' \
    --header 'X-BypassExternalValidation: true' \
    --header "Authorization: Basic $PF_CRED" \
    --header 'Content-Type: application/json' \
    --data-raw '{
    "id": "DemoSMTP",
    "name": "DemoSMTP",
    "pluginDescriptorRef": {
    "id": "com.pingidentity.email.SmtpNotificationPlugin"
    },
        "configuration": {
            "fields": [
            {
                "name": "From Address",
                "value": "noreply@any-company.org"
            },
            {
                "name": "Email Server",
                "value": "0.0.0.0"
            },
            {
                "name": "Test Address",
                "value": "testuser@gmail.com"
            }
            ]
        }
    }' | jq -rc '.id')
    verify_notification_publisher
}
create_notification_publisher

####################################### Verify HTML form Adapter Creation #######################################
adapter_try=0

function verify_adapter() {
    # Verify if HTML form adapter is created.
    VERIFY_ADAPTER=$(echo "$CREATE_ADAPTER" |  sed 's@.*}@@')
    if [[ "$VERIFY_ADAPTER" == "201" ]]; then
        echo "Created HTML form adapter..."
    elif [[ "$VERIFY_ADAPTER" != "201" ]] && [[ "$adapter_try" -lt "$api_call_retry_limit" ]]; then
        check_htmlform
        if [[ "$CHECK_HTML_FORM_NAME" == "SampleHtmlForm" ]]; then
            echo "HTML Form adapter with the same name already exists..."
        else
            adapter_tries_left=$((api_call_retry_limit-adapter_try))
            echo "HTML form adapter not created, retrying $adapter_tries_left more time(s)..."
            adapter_try=$((adapter_try+1))
            create_adapter
        fi
    else
        echo "HTML form adapter not created and exceeded try limit!"
        exit 1
    fi
}

function check_htmlform() {
    CHECK_HTML_FORM_NAME=$(curl -s --insecure --location --request GET "https://$PINGFED_BASE_URL/pf-admin-api/v1/idp/adapters" \
    --header 'X-XSRF-Header: PASS' \
    --header "Authorization: Basic $PF_CRED" | jq -rc '.items[] | select(.name=="SampleHtmlForm") | .name')
}
####################################### Create HTML form adapter #######################################

function create_adapter() {

    CREATE_ADAPTER=$(curl -s --insecure --write-out "%{http_code}\n" --location --request POST "https://$PINGFED_BASE_URL/pf-admin-api/v1/idp/adapters" \
                --header 'X-XSRF-Header: PASS' \
                --header 'X-BypassExternalValidation: true' \
                --header "Authorization: Basic $PF_CRED" \
                --header 'Content-Type: application/json' \
                --data-raw '{
                "id": "HtmlformDemo",
                "name": "SampleHtmlForm",
                "pluginDescriptorRef": {
                    "id": "com.pingidentity.adapters.htmlform.idp.HtmlFormIdpAuthnAdapter"
                },
                "configuration": {
                    "tables": [
                    {
                        "name": "Credential Validators",
                        "rows": [
                        {
                            "fields": [
                            {
                                "name": "Password Credential Validator Instance",
                                "value": "'"$PCV_ID"'"
                            }
                            ]
                        }
                        ]
                    }
                    ],
                    "fields": [
                        {
                            "name": "Allow Password Changes",
                            "value": "true"
                        },
                        {
                            "name": "Password Reset Type",
                            "value": "OTL"
                        },
                        {
                            "name": "Notification Publisher",
                            "value": "'"$NP_ID"'"
                        }
                    ]
                },
                "attributeContract": {
                        "coreAttributes": [
                        {
                            "name": "username",
                            "masked": false,
                            "pseudonym": true
                        }
                        ]
                }
                }')
            verify_adapter
}
create_adapter

echo "------ End of 403-pf_solutions_set.sh ######"
