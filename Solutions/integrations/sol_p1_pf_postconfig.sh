#!/bin/bash

# runs Solutions pre-configs for PingFederate...

# Variables needed to pass for this script:
# API_LOCATION
# ENV_ID
# WORKER_APP_ACCESS_TOKEN
# PINGFED_BASE_URL
# PF_USERNAME
# PF_PASSWORD

echo "###### Beginning of Solutions PingOne PingFederate Pre-Config Tasks ######"

echo "------ Start of PingFederate Gateway creation ------"
#set some individual counts
create_gw_ct=0
create_gw_cred_ct=0

function make_gw() {
    #create the gateway and set the id to this variable.
    CREATE_GW=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/gateways" \
        --header 'Content-Type: application/json' \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
        --data-raw '{
          "name": "Ping Federate Demo Gateway",
          "description": "Gateway connection linking PingFederate to PingOne. See https://apidocs.pingidentity.com/pingone/platform/v1/api/#gateway-management.",
          "type": "PING_FEDERATE",
          "enabled": true
        }')

    CREATE_GW_ID=$(echo $CREATE_GW | jq -rc .id)
    CREATE_GW_UNIQUENESS=$(echo $CREATE_GW | jq -rc '.details[]?.code')

    #regex check if set to a uuid, uniqueness check if not unique.
    if [[ "$CREATE_GW_ID" =~ ^\{?[A-F0-9a-f]{8}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{12}\}?$ ]] \
        && [[ "$CREATE_GW_UNIQUENESS" != "UNIQUENESS_VIOLATION" ]]; then
        echo "Ping Federate Demo Gateway create successfully."
        make_gw_cred
    elif [[ "$CREATE_GW_UNIQUENESS" == "UNIQUENESS_VIOLATION" ]]; then
        #script was interupted before completion, gateway exists already. Grabbing that id.
        unset CREATE_GW_ID
        CREATE_GW_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/gateways" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
        | jq -rc '._embedded.gateways[] | select(.name=="Ping Federate Demo Gateway") | .id')
        if [[ "$CREATE_GW_ID" =~ ^\{?[A-F0-9a-f]{8}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{12}\}?$ ]]; then
          echo "Ping Federate Demo Gateway already exists, found existing ID."
          make_gw_cred
        fi
    else
        #check if we're at the limit or not. if not retry.
        if [[ "$create_gw_ct" -lt "$api_call_retry_limit" ]]; then
            echo "Gateway was not created successfully, retrying."
            create_gw_ct=$((create_gw_ct+1))
            make_gw
        else
            echo "Gateway was not created successfully and tries exceeded limit. Exiting now."
            exit 1
        fi
    fi
}

function assign_gw_roles () {
    P1_ROLES=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/roles" \
              --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | \
              jq -rc '._embedded.roles[] | select ((.name == "Environment Admin") or (.name == "Identity Data Admin")) | .id')
    if [[ "$P1_ROLES" =~ ^\{?[A-F0-9a-f]{8}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{12}$'\n'[A-F0-9a-f]{8}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{12} ]]; then
      GW_ROLES=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/gateways/$CREATE_GW_ID/roleAssignments" \
                --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | \
                jq -rc '._embedded.roleAssignments[].role.id')
      MISSING_GW_ROLES=$(echo ${P1_ROLES[@]} ${GW_ROLES[@]} | tr ' ' '\n' | sort | uniq -u)
      for GW_ROLE_ADD in $MISSING_GW_ROLES; do
        ADD_GW_ROLE=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/gateways/$CREATE_GW_ID/roleAssignments" \
                    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
                    --header 'Content-Type: application/json' \
                    --data-raw '{
                                  "role": {
                                    "id": "'"$GW_ROLE_ADD"'"
                                  },
                                  "scope": {
                                    "id": "'"$ENV_ID"'",
                                    "type": "ENVIRONMENT"
                                  }
                                }')
      done
    elif [[ "$create_gw_ct" -lt "$api_call_retry_limit" ]]; then
      assign_gw_roles
    else
      echo "Gateway role query has failed and retries exceeded. Exiting now."
      exit 1
    fi
}

function make_gw_cred () {
    #create the gateway credential to tie to PF
    #delete any existing credentials that have not been used in case script fails.
    EXISTING_GW_CRED=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/gateways/$CREATE_GW_ID/credentials" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | \
        jq -rc '._embedded.credentials[] | select ( has("lastUsedAt") == false) | .id')
    #loop to delete
    if [[ "$EXISTING_GW_CRED" =~ ^\{?[A-F0-9a-f]{8}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{12} ]]; then
      for GW_CREDENTIAL in $EXISTING_GW_CRED; do
        DELETE_GW_CRED=$(curl -s --location --request DELETE "$API_LOCATION/environments/$ENV_ID/gateways/$CREATE_GW_ID/credentials/$GW_CREDENTIAL" \
                          --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN")
      done
    fi
    #make the new one
    CREATE_GW_CRED=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/gateways/$CREATE_GW_ID/credentials" \
        --header 'Content-Type: application/json' \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | \
        jq -rc '.credential')
    #check if set
    if [[ "$CREATE_GW_CRED" == "eyJ"* ]]; then
        echo "Gateway credential created successfully, passing to PF."
        link_pf_p1
    else
        #check if we're at the limit or not. if not retry.
        if [[ "$create_gw_cred_ct" -lt "$api_call_retry_limit" ]]; then
            echo "Gateway credential not created, retrying."
            make_gw_cred
        else
            echo "Gateway credential not created successfully and tries exceeded limit. Exiting now."
            exit 1
        fi
    fi
}

function link_pf_p1 () {
    #encode PF credentials
    PF_CRED=$(echo -n "$PF_USERNAME:$PF_PASSWORD" | base64)
    #create link in PF
    GW_LINK=$(curl -s -k --location --request POST "$PINGFED_BASE_URL/pf-admin-api/v1/pingOneConnections" \
        --header 'Content-Type: application/json' \
        --header 'X-XSRF-Header: pingfederate' \
        --header "Authorization: Basic $PF_CRED" \
        --data-raw '{
          "name": "PING_ONE_TO_PING_FED_DEMO_GATEWAY",
          "active": true,
          "credential": "'"$CREATE_GW_CRED"'"
        }')
    if [[ "$GW_LINK" == *"PING_ONE_TO_PING_FED_DEMO_GATEWAY"* ]]; then
        #great success!
        echo "Gateway created successfully in PingFederate."
    else
        #check if we're at the limit or not. if not retry.
        if [[ "$link_gw_ct" -lt "$api_call_retry_limit" ]]; then
            echo "Gateway not linked successfully in Ping Federate, retrying."
            link_gw_ct=$((link_gw_ct+1))
            link_pf_p1
        else
            echo "Gateway not linked successfully in Ping Federate and tries exceeded limit. Exiting now."
            exit 1
        fi
    fi
}

#start everything up
make_gw
echo "------ End of PingFederate gateway setup ------"

echo "------ Start of PingFederate adapter setup ------"

#create adapters within PF
risk_adapter_ct=0
function create_risk_adapter () {
    #base64 encode the credentials to use in a request.
    PF_CRED=$(echo -n "$PF_USERNAME:$PF_PASSWORD" | base64)

    #pulling to use this for further info. This gets the pingone connection info from PingFed(using for env info)
    GW_INFO=$(curl -s -k --location --request GET "$PINGFED_BASE_URL/pf-admin-api/v1/pingOneConnections" \
            --header 'Content-Type: application/json' \
        --header 'X-XSRF-Header: pingfederate' \
        --header "Authorization: Basic $PF_CRED" )

    #get env id and whatever that encrypted/encoded/whatever value is.
    GW_VAL=$(echo "$GW_INFO" | jq -rc '.items[0].id + "|" + .items[0].environmentId')

    #figure out how we install risk adapter (CIAM/WF). Does mean this has to follow solutions_pre-config.sh
    if [[ "$BOM_RESULT" == *"PING_ONE_MFA"* ]]; then
        RISK_POL_SET_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/riskPolicySets" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.riskPolicySets[]  | select(.name=="Default CIAM Risk Policy") | .id')
    elif [[ "$BOM_RESULT" == *"PING_ID"* ]]; then
        RISK_POL_SET_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/riskPolicySets" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.riskPolicySets[]  | select(.name=="Default Workforce High Risk Policy") | .id')
    fi

    #create demo p1 risk adapter in PF
    RISK_ADAPTER=$(curl -s -k --location --request POST "$PINGFED_BASE_URL/pf-admin-api/v1/idp/adapters" \
    --header 'Content-Type: application/json' \
    --header 'X-XSRF-Header: pingfederate' \
    --header "Authorization: Basic $PF_CRED" \
    --data-raw '{
        "id": "demop1risk",
        "name": "Demo PingOne Risk Adapter",
        "pluginDescriptorRef": {
          "id": "com.pingidentity.adapters.pingone.risk.PingOneRiskManagementIdpAdapter",
          "location": "'"$PINGFED_BASE_URL"'/pf-admin-api/v1/idp/adapters/descriptors/com.pingidentity.adapters.pingone.risk.PingOneRiskManagementIdpAdapter"
        },
        "configuration": {
          "tables": [
            {
              "name": "Additional User Attributes (optional)",
              "rows": []
            },
            {
              "name": "PingOne Risk API Response Mappings (optional)",
              "rows": []
            }
          ],
          "fields": [
            {
              "name": "PingOne Environment",
              "value": "'"$GW_VAL"'"
            },
            {
              "name": "Risk Policy ID",
              "value": "'"$RISK_POL_SET_ID"'"
            },
            {
              "name": "Include Device Profile",
              "value": "true"
            },
            {
              "name": "Device Profiling Method",
              "value": "Captured by this adapter"
            },
            {
              "name": "Device Profiling Timeout",
              "value": "5000"
            },
            {
              "name": "Cookie Name Prefix",
              "value": "pingone.risk.device.profile"
            },
            {
              "name": "Failure Mode",
              "value": "Continue with fallback policy decision"
            },
            {
              "name": "Fallback Policy Decision Value",
              "value": "MEDIUM"
            },
            {
              "name": "API Request Timeout",
              "value": "2000"
            },
            {
              "name": "Proxy Settings",
              "value": "System Defaults"
            },
            {
              "name": "Custom Proxy Host",
              "value": ""
            },
            {
              "name": "Custom Proxy Port",
              "value": ""
            }
          ]
        },
        "attributeContract": {
          "coreAttributes": [
            {
              "name": "riskLevel",
              "masked": false,
              "pseudonym": false
            },
            {
              "name": "riskValue",
              "masked": false,
              "pseudonym": true
            }
          ],
          "extendedAttributes": [],
          "maskOgnlValues": false
        },
        "attributeMapping": {
          "attributeSources": [],
          "attributeContractFulfillment": {
            "riskLevel": {
              "source": {
                "type": "ADAPTER"
              },
              "value": "riskLevel"
            },
            "riskValue": {
              "source": {
                "type": "ADAPTER"
              },
              "value": "riskValue"
            }
          },
          "issuanceCriteria": {
            "conditionalCriteria": []
          }
        }
    }')
    if [[ "$RISK_ADAPTER" == *"Demo PingOne Risk Adapter"* ]]; then
        echo "Demo P1 Risk Adapter created successfully in PingFederate."
    else
        if [[ "$risk_adapter_ct" -lt "$api_call_retry_limit" ]]; then
            create_risk_adapter
        else
            echo "Risk adapter not created successfully."
        fi
    fi
}

mfa_adapter_ct=0
function create_mfa_adapter () {
    #base64 encode the credentials to use in a request.
    PF_CRED=$(echo -n "$PF_USERNAME:$PF_PASSWORD" | base64)

    #pulling to use this for further info.
    GW_INFO=$(curl -s -k --location --request GET "$PINGFED_BASE_URL/pf-admin-api/v1/pingOneConnections" \
            --header 'Content-Type: application/json' \
        --header 'X-XSRF-Header: pingfederate' \
        --header "Authorization: Basic $PF_CRED" )

    #get env id and whatever that encrypted/encoded/whatever value
    GW_VAL=$(echo "$GW_INFO" | jq -rc '.items[0].id + "|" + .items[0].environmentId')

    #Get the default population ID
    SELF_POP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    | jq -rc '._embedded.populations[] | select(.name=="Sample Users") | .id')

    #create demo p1 mfa adapter in PF
    MFA_ADAPTER=$(curl -s -k --location --request POST "$PINGFED_BASE_URL/pf-admin-api/v1/idp/adapters" \
    --header 'Content-Type: application/json' \
    --header 'X-XSRF-Header: pingfederate' \
    --header "Authorization: Basic $PF_CRED" \
    --data-raw '{
        "id": "demop1mfa",
        "name": "Demo PingOne MFA Adapter",
        "pluginDescriptorRef": {
          "id": "com.pingidentity.adapters.pingone.mfa.PingOneMfaIdpAdapter",
          "location": "'"$PINGFED_BASE_URL"'/pf-admin-api/v1/idp/adapters/descriptors/com.pingidentity.adapters.pingone.mfa.PingOneMfaIdpAdapter"
        },
        "configuration": {
          "tables": [],
          "fields": [
            {
              "name": "PingOne Environment",
              "value": "'"$GW_VAL"'"
            },
            {
              "name": "PingOne Population",
              "value": "'"$SELF_POP_ID"'"
            },
            {
              "name": "Application Client ID",
              "value": "'"$PF_WORKER_CLIENT_ID"'"
            },
            {
              "name": "Application Client Secret",
              "value": "'"$PF_WORKER_CLIENT_SECRET"'"
            },
            {
              "name": "PingOne Authentication Policy",
              "value": "Single_Factor"
            },
            {
              "name": "Test Username",
              "value": ""
            },
            {
              "name": "HTML Template Prefix",
              "value": "pingone-mfa"
            },
            {
              "name": "Messages Files",
              "value": "pingone-mfa-messages"
            },
            {
              "name": "Provision Users and Authentication Methods",
              "value": "true"
            },
            {
              "name": "Update Authentication Methods",
              "value": "true"
            },
            {
              "name": "Username Attribute",
              "value": ""
            },
            {
              "name": "SMS Attribute",
              "value": "sms"
            },
            {
              "name": "Email Attribute",
              "value": "email"
            },
            {
              "name": "DEFAULT AUTHENTICATION METHOD FOR PROVISIONED USERS",
              "value": "SMS"
            },
            {
              "name": "User Not Found Failure Mode",
              "value": "Block user"
            },
            {
              "name": "Service Unavailable Failure Mode",
              "value": "Bypass authentication"
            },
            {
              "name": "Change Device",
              "value": "Allow"
            },
            {
              "name": "Show Success Screens",
              "value": "true"
            },
            {
              "name": "Show Error Screens",
              "value": "true"
            },
            {
              "name": "Show Timeout Screens",
              "value": "true"
            },
            {
              "name": "API Request Timeout",
              "value": "5000"
            },
            {
              "name": "Proxy Settings",
              "value": "System Defaults"
            },
            {
              "name": "Custom Proxy Host",
              "value": ""
            },
            {
              "name": "Custom Proxy Port",
              "value": ""
            }
          ]
        },
        "attributeContract": {
          "coreAttributes": [
            {
              "name": "access_token",
              "masked": false,
              "pseudonym": false
            },
            {
              "name": "pingone.mfa.status",
              "masked": false,
              "pseudonym": false
            },
            {
              "name": "id_token",
              "masked": false,
              "pseudonym": true
            },
            {
              "name": "pingone.mfa.status.reason",
              "masked": false,
              "pseudonym": false
            },
            {
              "name": "username",
              "masked": false,
              "pseudonym": false
            }
          ],
          "extendedAttributes": [],
          "maskOgnlValues": false
        },
        "attributeMapping": {
          "attributeSources": [],
          "attributeContractFulfillment": {
            "access_token": {
              "source": {
                "type": "ADAPTER"
              },
              "value": "access_token"
            },
            "pingone.mfa.status": {
              "source": {
                "type": "ADAPTER"
              },
              "value": "pingone.mfa.status"
            },
            "id_token": {
              "source": {
                "type": "ADAPTER"
              },
              "value": "id_token"
            },
            "pingone.mfa.status.reason": {
              "source": {
                "type": "ADAPTER"
              },
              "value": "pingone.mfa.status.reason"
            },
            "username": {
              "source": {
                "type": "ADAPTER"
              },
              "value": "username"
            }
          },
          "issuanceCriteria": {
            "conditionalCriteria": []
          }
        }
    }')
        if [[ "$MFA_ADAPTER" == *"Demo PingOne MFA Adapter"* ]]; then
            echo "Demo P1 MFA Adapter created successfully in PingFederate."
        else
            if [[ "$mfa_adapter_ct" -lt "$api_call_retry_limit" ]]; then
                create_mfa_adapter
            else
                echo "MFA adapter not created successfully."
            fi
        fi
}

#call risk and mfa create functions if PF turned on
#only run if risk is enabled.
if [[ "$BOM_RESULT" == *"PING_ONE_RISK"* ]]; then
    create_risk_adapter
fi

#only run MFA if enabled. CIAM only at this time. Will have respective one for PingID in the future.
#commenting out for now due to perm problems.
#if [[ "$BOM_RESULT" == *"PING_ONE_MFA"* ]]; then
#    create_mfa_adapter
#fi

echo "------ End of PingFederate adapter setup ------"


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
            echo "Data Store with $CHECK_DS_NAME name already exists..."
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
    CHECK_DS_NAME=$(curl -s -k --location --request GET "$PINGFED_BASE_URL/pf-admin-api/v1/dataStores" \
    --header 'X-XSRF-Header: PASS' \
    --header "Authorization: Basic $PF_CRED" | jq -rc '.items[] | select(.name=="Demo LDAP Data Store") | .name')
}
####################################### Add Active Directory Data Store #######################################

function create_ds() {
    DS_ID=$(curl -s -k --location --request POST "$PINGFED_BASE_URL/pf-admin-api/v1/dataStores" \
        --header "X-XSRF-Header: PASS" \
        --header 'X-BypassExternalValidation: true' \
        --header "Authorization: Basic $PF_CRED" \
        --header "Content-Type: application/json" \
        --data-raw '{
        "type": "LDAP",
        "name": "Demo LDAP Data Store",
        "useSsl":true,
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
    if [[ $PCV_ID == "DemoID" ]]; then
        echo "Created LDAP PCV..."
    elif [[ -z ${PCV_ID+x} ]] || [[ "$PCV_ID" == "null" ]] || [[ $PCV_SET == *"already defined"* ]]; then
      if [[ "$pcv_try" -lt "$api_call_retry_limit" ]]; then
          check_pcv
        if [[ "$CHECK_PCV_NAME" == "DemoPCV" ]]; then
            echo "LDAP PCV with $CHECK_PCV_NAME name already exists..."
        else
            pcv_tries_left=$((api_call_retry_limit-pcv_try))
            echo "LDAP PCV not created, retrying $pcv_tries_left more time(s)..."
            pcv_try=$((pcv_try+1))
            create_pcv
        fi
      fi
    else
        echo "LDAP PCV not created and exceeded try limit!"
        exit 1
    fi
}

function check_pcv() {
    CHECK_PCV_NAME=$(curl -s -k --location --request GET "$PINGFED_BASE_URL/pf-admin-api/v1/passwordCredentialValidators" \
    --header 'X-XSRF-Header: PASS' \
    --header "Authorization: Basic $PF_CRED" | jq -rc '.items[] | select(.name=="DemoPCV") | .name')
}

####################################### Create LDAP Password Credential Validator #######################################

function create_pcv() {
    PCV_SET=$(curl -s -k --location --request POST "$PINGFED_BASE_URL/pf-admin-api/v1/passwordCredentialValidators" \
            --header 'X-XSRF-Header: PASS' \
            --header 'X-BypassExternalValidation: true' \
            --header "Authorization: Basic $PF_CRED" \
            --header 'Content-Type: application/json' \
            --data-raw '{
            "id": "DemoID",
            "name": "DemoPCV",
            "pluginDescriptorRef": {
                "id": "org.sourceid.saml20.domain.LDAPUsernamePasswordCredentialValidator",
                "location": "'"$PINGFED_BASE_URL/pf-admin-api/v1/passwordCredentialValidators/descriptors/org.sourceid.saml20.domain.LDAPUsernamePasswordCredentialValidator"'"
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
            }')

    PCV_ID=$(echo $PCV_SET | jq -rc '.id')
    verify_pcv
}
create_pcv

####################################### Verify Notification Publisher creation #######################################
np_try=0

function verify_notification_publisher {
    # Checks for Notification Publisher ID to verify if Notification Publisher is created.
    if [[ "$NP_ID" == "DemoSMTP" ]]; then
      echo "Created Notification Publisher..."
    #check if either unset/null/or if NP_SET returns id already exists
    elif [[ -z ${NP_ID+x} ]] || [[ "$NP_ID" == "null" ]] || [[ $NP_SET == *"already defined"* ]]; then
      if [[ "$np_try" -lt "$api_call_retry_limit" ]]; then
        check_notification_publisher
        if [[ "$CHECK_NP_NAME" == "DemoSMTP" ]]; then
            echo "Notificiation Publisher with $CHECK_NP_NAME name already exists..."
        else
            np_tries_left=$((api_call_retry_limit-np_try))
            echo "Notification Publisher not created, retrying $np_tries_left more time(s)..."
            np_try=$((np_try_try+1))
            create_notification_publisher
        fi
      fi
    else
        echo "Notification Publisher not created and exceeded try limit!"
        exit 1
    fi
}

function check_notification_publisher() {
    CHECK_NP_NAME=$(curl -s -k --location --request GET "$PINGFED_BASE_URL/pf-admin-api/v1/notificationPublishers" \
    --header 'X-XSRF-Header: PASS' \
    --header "Authorization: Basic $PF_CRED" | jq -rc '.items[] | select(.name=="DemoSMTP") | .name')
}

######################################## Create Notiifcation Publisher #######################################

function create_notification_publisher {
    NP_SET=$(curl -s -k --location --request POST "$PINGFED_BASE_URL/pf-admin-api/v1/notificationPublishers" \
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
        }')
    #split this in case already exists
    NP_ID=$(echo $NP_SET | jq -rc '.id')
    #next step
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
            echo "HTML Form adapter with $CHECK_HTML_FORM_NAME name already exists..."
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
    CHECK_HTML_FORM_NAME=$(curl -s -k --location --request GET "$PINGFED_BASE_URL/pf-admin-api/v1/idp/adapters" \
    --header 'X-XSRF-Header: PASS' \
    --header "Authorization: Basic $PF_CRED" | jq -rc '.items[] | select(.name=="SampleHtmlForm") | .name')
}
####################################### Create HTML form adapter #######################################

function create_adapter() {

    CREATE_ADAPTER=$(curl -s -k --write-out "%{http_code}\n" --location --request POST "$PINGFED_BASE_URL/pf-admin-api/v1/idp/adapters" \
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

############################################## Create CIDR Selector ##############################################

# Verify if PingID adapter is created
cidr_try=0
function verify_cidr() {
# Checks for Password Credential Validator ID to verify if PCV is created.
    if [[ $CIDR_ID =~ ^[A-Za-z0-9]{1,33}$ ]] && [[ $CIDR_ID != null ]]; then
        echo "Created CIDR Selector."
    elif ([[ -z ${CIDR_ID+x} ]] || [[ $CIDR_ID == null ]]) && [[ "$cidr_try" -lt "$api_call_retry_limit" ]]; then
        check_cidr
        if [[ "$CHECK_CIDR_NAME" == "CIDRdemo" ]]; then
            echo "CIDR selector with $CHECK_CIDR_NAME name already exists..."
        else
            cidr_tries_left=$((api_call_retry_limit-cidr_try))
            echo "CIDR selector not created, retrying $cidr_tries_left more time(s)..."
            cidr_try=$((cidr_try+1))
            create_cidr
        fi
    else
        echo "CIDR selector not created and exceeded try limit!"
        exit 1
    fi
}
#Checks for PCV name to see if PCV with the same name exists
function check_cidr() {
    CHECK_CIDR_NAME=$(curl -s -k --location --request GET "$PINGFED_BASE_URL/pf-admin-api/v1/authenticationSelectors" \
    --header 'X-XSRF-Header: PASS' \
    --header "Authorization: Basic $PF_CRED" | jq -rc '.items[] | select(.name=="CIDRdemo") | .name')
}
# Create CIDR Selector
function create_cidr() {
    CIDR_ID=$(curl -s -k --location --request POST "$PINGFED_BASE_URL/pf-admin-api/v1/authenticationSelectors" \
        --header 'X-XSRF-Header: PASS' \
        --header 'X-BypassExternalValidation: true' \
        --header "Authorization: Basic $PF_CRED" \
        --header 'Content-Type: application/json' \
        --data-raw '{
            "id": "CIDRid",
            "name": "CIDRdemo",
            "pluginDescriptorRef": {
            "id": "com.pingidentity.pf.selectors.cidr.CIDRAdapterSelector"
            },
            "configuration": {
            "tables": [
                {
                "name": "Networks",
                "rows": [
                    {
                    "fields": [
                        {
                        "name": "Network Range (CIDR notation)",
                        "value": "0.0.0.0./0"
                        }
                    ]
                    }
                ]
                }
            ]
            }
        }' | jq -rc '.id')
    verify_cidr
}
create_cidr

############################################## Create PingID Adapter ##############################################
# Verify if PingID adapter is created
pingid_try=0
function verify_pingid() {
    # Checks for Password Credential Validator ID to verify if PCV is created.
    if [[ $PINGID_ID =~ ^[A-Za-z0-9]{1,33}$ ]] && [[ $PINGID_ID != null ]]; then
        echo "Created PingID adapter."
    elif ([[ -z ${PINGID_ID+x} ]] || [[ "$PINGID_ID" == "null" ]]) && [[ "$pingid_try" -lt "$api_call_retry_limit" ]]; then
        check_pingid
        if [[ "$CHECK_PINGID_NAME" == "SamplePingID" ]]; then
            echo "PingID adapter with $CHECK_PINGID_NAME name already exists..."
        else
            pingid_tries_left=$((api_call_retry_limit-pingid_try))
            echo "PingID adapter not created, retrying $pingid_tries_left more time(s)..."
            pingid_try=$((pingid_try+1))
        fi
    else
        echo "PingID adapter not created and exceeded try limit!"
        exit 1
    fi
}
#Checks for PingID adapter to see if the adapter  with the same name exists
function check_pingid() {
    CHECK_PINGID_NAME=$(curl -s -k --location --request GET "$PINGFED_BASE_URL/pf-admin-api/v1/idp/adapters" \
    --header 'X-XSRF-Header: PASS' \
    --header "Authorization: Basic $PF_CRED" | jq -rc '.items[] | select(.name=="SamplePingID") | .name')
}
# Create PingID adapter
function create_pingid() {
    PINGID_ID=$(curl -s -k --location --request POST "$PINGFED_BASE_URL/pf-admin-api/v1/idp/adapters" \
    --header 'X-XSRF-Header: PASS' \
    --header "Authorization: Basic $PF_CRED" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "id": "PingIDdemo",
        "name": "SamplePingID",
        "pluginDescriptorRef": {
            "id": "com.pingidentity.adapters.pingid.PingIDAdapter"
        },
        "configuration": {},
        "attributeContract": {
            "coreAttributes": [
            {
                "name": "subject",
                "masked": false,
                "pseudonym": true
            }
            ]
        }
    }' | jq -rc '.id')
    verify_pingid
}

create_pingid

############################################## Create Authentication Policy with CIDR selector and PingID adapter added as authentication sources  ##############################################

# Check to see if Authentication Policy with the same name exists
function check_authnpolicy() {
    VERIFY_POLICY_NAME=$(curl -s -k --location --request GET "$PINGFED_BASE_URL/pf-admin-api/v1/authenticationPolicies/default" \
    --header 'X-XSRF-Header: PASS' \
    --header "Authorization: Basic $PF_CRED" | jq -rc '.authnSelectionTrees[] | select(.name=="CIDR Demo Policy") | .name')
}

# Verify if authentication policy was created
authnpolicy_try=0

function verify_authnpolicy() {
    if [[ "$SET_POLICY" == "200" ]]; then
        echo "Created Authentication Policy."
    elif ([[ -z ${VERIFY_POLICY_NAME+x} || "$VERIFY_POLICY_NAME" != "CIDR Demo Policy" || "$SET_POLICY" != "200" ]]) && [[ "$authnpolicy_try" -lt "$api_call_retry_limit" ]]; then
        authnpolicy_tries_left=$((api_call_retry_limit-authnpolicy_try))
        echo "Authentication Policy cannot be created. retrying $authnpolicy_tries_left more time(s)..."
        authnpolicy_try=$((authnpolicy_try+1))
        set_authnpolicy
    else
        echo "Authentiation Policy cannot be created and exceeded the retry limit"
        exit 1
    fi
}

# Create Authentication Policy if there are no policies with the same name as "CIDR Demo Policy" in Ping Federate
function set_authnpolicy() {
    check_authnpolicy
    if [[ "$VERIFY_POLICY_NAME" == "CIDR Demo Policy" ]]; then
    echo "Authenticaion Policy with $VERIFY_POLICY_NAME name already exists..."
    else
        SET_POLICY=$(curl -s -k --write-out "%{http_code}\n" --location --request PUT "$PINGFED_BASE_URL/pf-admin-api/v1/authenticationPolicies/default" \
        --header 'X-XSRF-Header: PASS' \
        --header 'X-BypassExternalValidation: true' \
        --header "Authorization: Basic $PF_CRED" \
        --header 'Content-Type: application/json' \
        --data-raw '{
        "failIfNoSelection": true,
        "authnSelectionTrees": [
            {
            "rootNode": {
                "action": {
                "type": "AUTHN_SELECTOR",
                "authenticationSelectorRef": {
                    "id": "'$CIDR_ID'"
                }
                },
                "children": [
                {
                    "action": {
                    "type": "AUTHN_SOURCE",
                    "context": "No",
                    "authenticationSource": {
                        "type": "IDP_ADAPTER",
                        "sourceRef": {
                        "id": "'$PINGID_ID'"
                        }
                    }
                    },
                    "children": [
                    {
                        "action": {
                        "type": "DONE",
                        "context": "Fail"
                        }
                    },
                    {
                        "action": {
                        "type": "DONE",
                        "context": "Success"
                        }
                    }
                    ]
                },
                {
                    "action": {
                    "type": "CONTINUE",
                    "context": "Yes"
                    }
                }
                ]
            },
            "name": "CIDR Demo Policy",
            "enabled": true
            }
        ],
        "defaultAuthenticationSources": [],
        "trackedHttpParameters": []
        }' | sed s@.*}@@)
        verify_authnpolicy
    fi
}
set_authnpolicy
echo "###### End of Solutions PingFederate Pre-Config Tasks ######"
