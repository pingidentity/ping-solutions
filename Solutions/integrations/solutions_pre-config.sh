#!/bin/bash

# runs Solutions pre-configs against for CIAM or WF use-cases in PingOne Environment

# Variables needed to run script
# API_LOCATION
# ENV_ID
# WORKER_APP_ACCESS_TOKEN
function ciam() {
    #define script for job.
    echo "------ Beginning Risk Policy Set for CIAM ------"

    # set global api call retry limit - this can be set to desired amount, default is 2
    api_call_retry_limit=1

    risk_pol_set=0

    function check_risk_policy() {
        # validate expected risk policy name change
        RISK_POL_STATUS=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/riskPolicySets" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
        | jq -rc '._embedded.riskPolicySets[]  | select(.name=="Default CIAM Risk Policy") | .name')

        # check expected name from config change
        if [ "$RISK_POL_STATUS" = "Default CIAM Risk Policy" ] && [[ "$risk_pol_set" -lt "$api_call_retry_limit" ]]; then
            echo "Verified Default CIAM Risk Policy set successfully..."
        elif [ "$RISK_POL_STATUS" != "Default CIAM Risk Policy" ] && [[ "$risk_pol_set" -lt "$api_call_retry_limit" ]]; then
            #put a stop to the madness (potentially) by incrementing the total limit
            risk_pol_set=$((risk_pol_set+1))
            set_risk_policy
        else
            echo "Default CIAM Risk Policy NOT set successfully!"
            exit 1
        fi
    }

    function set_risk_policy() {
    # Get Current Default Risk Policy
    RISK_POL_SET_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/riskPolicySets" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.riskPolicySets[]  | select(.name=="Default Risk Policy") | .id')

    # Set Default Risk Policy to CIAM Name
    SET_RISK_POL_NAME=$(curl -s --write-out "%{http_code}\n" --location --request PUT "$API_LOCATION/environments/$ENV_ID/riskPolicySets/$RISK_POL_SET_ID" \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    --data-raw '{"name" : "Default CIAM Risk Policy",
            "default" : true,
            "canUseIntelligenceDataConsent": true,
            "description" : "For Use with PingFederate",
            "defaultResult" : {
            "level" : "LOW",
            "type" : "VALUE"
            },
            "riskPolicies" : [ {
            "name" : "GEOVELOCITY_ANOMALY",
            "priority" : 1,
            "result" : {
                "level" : "HIGH",
                "type" : "VALUE"
            },
            "condition" : {
                "equals" : true,
                "value" : "${details.impossibleTravel}"
            }
            },
            {
            "name" : "MEDIUM_WEIGHTED_POLICY",
            "priority" : 2,
            "result" : {
                "level" : "MEDIUM",
                "type" : "VALUE"
            },
            "condition" : {
                "between" : {
                "minScore" : 40,
                "maxScore" : 70
                },
                "aggregatedWeights" : [ {
                "value" : "${details.aggregatedWeights.anonymousNetwork}",
                "weight" : 4
                }, {
                "value" : "${details.aggregatedWeights.geoVelocity}",
                "weight" : 2
                }, {
                "value" : "${details.aggregatedWeights.ipRisk}",
                "weight" : 5
                }, {
                "value" : "${details.aggregatedWeights.userRiskBehavior}",
                "weight" : 0
                } ]
            }
            },
            {
            "name" : "HIGH_WEIGHTED_POLICY",
            "priority" : 3,
            "result" : {
                "level" : "HIGH",
                "type" : "VALUE"
            },
            "condition" : {
                "between" : {
                "minScore" : 70,
                "maxScore" : 100
                },
                "aggregatedWeights" : [ {
                "value" : "${details.aggregatedWeights.anonymousNetwork}",
                "weight" : 4
                }, {
                "value" : "${details.aggregatedWeights.geoVelocity}",
                "weight" : 2
                }, {
                "value" : "${details.aggregatedWeights.ipRisk}",
                "weight" : 5
                }, {
                "value" : "${details.aggregatedWeights.userRiskBehavior}",
                "weight" : 0
                } ]
            }
            } ]
    }')

        # check response code
        SET_RISK_POL_NAME_RESULT=$(echo $SET_RISK_POL_NAME | sed 's@.*}@@' )
        if [ "$SET_RISK_POL_NAME_RESULT" == "200" ] && [[ "$risk_pol_set" -lt "$api_call_retry_limit" ]]; then
            echo "Default CIAM Risk policy set, verifying content..."
            # check_risk_policy
        elif [[ "$SET_RISK_POL_NAME_RESULT" != "200" ]] &&  [[ "$risk_pol_set" -lt "$api_call_retry_limit" ]]; then
            echo "Default CIAM Risk policy not set! Verifying content to see if already exists..."
            check_risk_policy
        else
            echo "Default CIAM Risk policy unable to be set!"
            exit 1
        fi

    }

    function check_risk_enabled() {
    #check if the environment is allowed to use Risk
    RISK_ENABLED=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/capabilities" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '.canUseIntelligenceRisk')

    if [[ $RISK_ENABLED == true ]]; then
        #let's do the rest of this
        set_risk_policy
    else
        echo "**** PingOne Risk Management is not enabled for this environment! ****"
    fi
    }

    #check it's enabled (will attempt execute all functions if it is).
    check_risk_enabled

    #script finish
    echo "------ End Risk Policy Set for CIAM ------"

    echo "------ Beginning of Authentication Policy set for CIAM ------"

    #set some individual counts
    self_reg_ct=0
    any_method_ct=0
    passwordless_method_ct=0
    mfa_ct=0

    function def_pop_id () {
    #Get the default population ID
    SELF_POP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    | jq -rc '._embedded.populations[] | select(.name=="Sample Users") | .id')

    #call everything else
    self_reg_pol
    passwordless_sms_pol
    any_method_passwordless_pol
    mfa_pol
    }

    function self_reg_pol () {
    #create the new self-reg policy
    echo "Creating self-registration policy."
    SELF_POL_CREATE=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    --data-raw '{
        "name": "Demo_Self-Registration_Login_Policy",
        "default": "false",
        "description": "A sign-on policy that allows for single-factor self-registration for Demo purposes"
        }'
    )

    #Get the new SELF REG SFA ID
    SELF_POL_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    | jq -rc '._embedded.signOnPolicies[] | select(.name=="Demo_Self-Registration_Login_Policy") | .id')

    self_reg_action
    }

    function self_reg_action () {
    #Create the self-reg action
    if [ -z ${SELF_POL_ID+x} ] && [[ "$self_reg_ct" -lt "$api_call_retry_limit" ]]; then
        self_reg_pol
    elif [ -z ${SELF_POL_ID+x} ] && [[ "$self_reg_ct" -lt "$api_call_retry_limit" ]]; then
        self_reg_ct_left=$(api_call_retry_limit-self_reg_ct)
        echo "Demo_Self-Registration_Login_Policy could not be set, retrying $self_reg_ct_left more time(s)..."
        #limit retries
        self_reg_ct=$((self_reg_ct+1))
    fi
    #perform the curl action
    echo "Creating Demo_Self-Registration_Login_Policy action."
    SELF_ACTION_CREATE=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/signOnPolicies/$SELF_POL_ID/actions" \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    --data-raw '{
        "priority": 1,
        "type": "LOGIN",
        "recovery": {
        "enabled": true
        },
        "registration": {
        "enabled": true,
        "population": {
            "id": "'"$SELF_POP_ID"'"
        }
        }
        }'
    )
    #validate function success
    self_action_val
    }

    function self_action_val () {
    SELF_ACTION_VAL=$(echo $SELF_ACTION_CREATE | jq -rc '.registration.enabled')
    if [[ $SELF_ACTION_VAL == true ]]; then
        echo "Demo_Self-Registration_Login_Policy set successfully"
    elif [ -z ${SELF_ACTION_VAL+x} ] && [[ "$self_reg_ct" -lt "$api_call_retry_limit" ]]; then
        self_reg_action
    else
        echo "Demo_Self-Registration_Login_Policy action could not be set, exiting script."
        exit 1
    fi
    }

    function passwordless_sms_pol () {
    #moving on
    echo "Creating passwordless SMS policy."
    #create the new SMS auth policy
    SMS_POL_CREATE=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    --data-raw '{
        "name": "Demo_Passwordless_SMS_Login_Policy",
        "default": "false",
        "description": "A passwordless sign-on policy that allows SMS authentication for Demo purposes"
        }'
    )

    #Get the new SMS ID
    SMS_POL_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    | jq -rc '._embedded.signOnPolicies[] | select(.name=="Demo_Passwordless_SMS_Login_Policy") | .id')

    #limit retries
    passwordless_method_ct=$((passwordless_method_ct+1))
    sms_action
    }

    function sms_action () {
    #Create the SMS action
    if [ -z ${SMS_POL_ID+x} ] && [[ "$passwordless_method_ct" -lt "$api_call_retry_limit" ]]; then
        passwordless_sms_pol
    elif [ -z ${SMS_POL_ID+x} ] && [[ "$passwordless_method_ct" > "$api_call_retry_limit" ]]; then
        echo "Demo_Passwordless_SMS_Login_Policy could not be set, exiting script."
        exit 1
    fi
    echo "Creating Demo_Passwordless_SMS_Login_Policy action."
    SMS_ACTION_CREATE=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/signOnPolicies/$SMS_POL_ID/actions" \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    --data-raw '{
        "priority": 1,
        "type": "MULTI_FACTOR_AUTHENTICATION",
        "priority": 1,
        "noDevicesMode": "BLOCK",
        "sms": {
            "enabled": true
        },
        "boundBiometrics": {
            "enabled": false
        },
        "authenticator": {
            "enabled": false
        },
        "email": {
            "enabled": false
        },
        "securityKey": {
            "enabled": false
        }
        }'
    )
    #validate function success
    sms_action_val

    }

    function sms_action_val () {
    SMS_ACTION_VAL=$(echo $SMS_ACTION_CREATE | jq -rc '.sms.enabled')
    if [[ $SMS_ACTION_VAL == true ]]; then
        echo "Demo_Passwordless_SMS_Login_Policy set successfully"
    elif [ -z ${SMS_ACTION_VAL+x} ] && [[ "$passwordless_method_ct" -lt "$api_call_retry_limit" ]]; then
        sms_action
    else
        echo "Demo_Passwordless_SMS_Login_Policy action could not be set, exiting script."
        exit 1
    fi
    }

    function any_method_passwordless_pol () {
    #moving on again
    #create the new passwordless any method Demo policy
    echo "Creating any method passwordless policy."
    ALL_MFA_POL_CREATE=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    --data-raw '{
        "name": "Demo_Passwordless_Any_Method_Login_Policy",
        "default": "false",
        "description": "A passwordless sign-on policy that allows for FIDO2 Biometrics, Authenticator app, email, SMS, or security key authentication for Demo purposes"
        }'
    )

    #Get the new passwordless ID
    ALL_MFA_POL_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    | jq -rc '._embedded.signOnPolicies[] | select(.name=="Demo_Passwordless_Any_Method_Login_Policy") | .id')

    #limit retries
    any_method_ct=$((any_method_ct+1))
    any_method_passwordless_action
    }

    function any_method_passwordless_action () {
    #Create the passwordless action
    if [ -z ${ALL_MFA_POL_ID+x} ] && [[ "$any_method_ct" -lt "$api_call_retry_limit" ]]; then
        any_method_passwordless_pol
    elif [ -z ${ALL_MFA_POL_ID+x} ] && [[ "$any_method_ct" > "$api_call_retry_limit" ]]; then
        echo "Demo_Passwordless_Any_Method_Login_Policy could not be set, exiting script."
        exit 1
    fi
    echo "Creating Demo_Passwordless_Any_Method_Login_Policy action."
    ALL_MFA_ACTION_CREATE=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/signOnPolicies/$ALL_MFA_POL_ID/actions" \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    --data-raw '{
        "priority": 30,
        "type": "MULTI_FACTOR_AUTHENTICATION",
        "priority": 1,
        "noDevicesMode": "BLOCK",
        "sms": {
            "enabled": true
        },
        "boundBiometrics": {
            "enabled": true
        },
        "authenticator": {
            "enabled": true
        },
        "email": {
            "enabled": true
        },
        "securityKey": {
            "enabled": true
        }
        }'
    )
    #validate function success
    any_method_action_val

    }

    function any_method_action_val () {
    ALL_MFA_ACTION_VAL=$(echo $ALL_MFA_ACTION_CREATE | jq -rc '.sms.enabled')
    if [[ $ALL_MFA_ACTION_VAL == true ]]; then
        echo "Demo_Passwordless_Any_Method_Login_Policy set successfully"
    elif [ -z ${ALL_MFA_ACTION_VAL+x} ] && [[ "$any_method_ct" -lt "$api_call_retry_limit" ]]; then
        sms_action
    else
        echo "Demo_Passwordless_Any_Method_Login_Policy action could not be set, exiting script."
        exit 1
    fi
    }

    function mfa_pol () {
    #moving on again
    #create the new all-in step up Multi-factor Demo policy
    echo "Creating Demo multi-factor policy policy."
    MFA_POL_CREATE=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    --data-raw '{
        "name": "Demo_Multi_Factor_Login_Policy",
        "default": "false",
        "description": "A sign-on policy that requires primary username and password along with pre-configured additions for Demo purposes"
    }')


    #Get the new MFA ID
    MFA_POL_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    | jq -rc '._embedded.signOnPolicies[] | select(.name=="Demo_Multi_Factor_Login_Policy") | .id')

    #limit retries
    mfa_ct=$((mfa_ct+1))
    mfa_action_1
    }

    function mfa_action_1 () {
    #Create the action (pt 1 of 2)
    if [ -z ${MFA_POL_ID+x} ] && [[ "$mfa_ct" -lt "$api_call_retry_limit" ]]; then
        mfa_pol
    elif [ -z ${MFA_POL_ID+x} ] && [[ "$mfa_ct" > "$api_call_retry_limit" ]]; then
        echo "Demo_Multi_Factor_Login_Policy could not be set, exiting script."
        exit 1
    fi
    echo "Creating Demo_Multi_Factor_Login_Policy action 1."
    MFA_ACTION_CREATE1=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/signOnPolicies/$MFA_POL_ID/actions" \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    --data-raw '{
        "priority": 1,
        "type": "LOGIN",
        "recovery": {
        "enabled": true
        },
        "registration": {
        "enabled": true,
        "population": {
            "id": "'"$SELF_POP_ID"'"
            }
        }
        }'
    )
    mfa_action1_val

    }

    function mfa_action1_val () {
    MFA_ACTION1_VAL=$(echo $MFA_ACTION_CREATE1 | jq -rc '.registration.enabled')
    if [[ $MFA_ACTION1_VAL == true ]]; then
        echo "Demo_Multi_Factor_Login_Policy action 1 set successfully"
        mfa_action_2
    elif [ -z ${MFA_ACTION1_VAL+x} ] && [[ "$mfa_ct" -lt "$api_call_retry_limit" ]]; then
        mfa_action_1
    else
        echo "Demo_Multi_Factor_Login_Policy action 1 could not be set, exiting script."
        exit 1
    fi
    }

    function mfa_action_2 () {
    #Create the action (pt 2 of 2)
    echo "Creating Demo_Multi_Factor_Login_Policy action 2."
    MFA_ACTION_CREATE2=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/signOnPolicies/$MFA_POL_ID/actions" \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    --data-raw '{
        "priority": 2,
        "type": "MULTI_FACTOR_AUTHENTICATION",
        "condition": {
            "secondsSince": "${session.lastSignOn.withAuthenticator.mfa.at}",
            "greater": 300
            },
        "priority": 2,
        "noDevicesMode": "BLOCK",
        "sms": {
            "enabled": true
            },
        "boundBiometrics": {
            "enabled": true
            },
        "authenticator": {
            "enabled": true
            },
        "email": {
            "enabled": true
            },
        "securityKey": {
            "enabled": true
            }
        }'
    )
    }

    function mfa_action2_val () {
    MFA_ACTION2_VAL=$(echo $MFA_ACTION_CREATE2 | jq -rc '.sms.enabled')
    if [[ $MFA_ACTION2_VAL == true ]]; then
        echo "Demo_Passwordless_SMS_Login_Policy set successfully"
    elif [ -z ${MFA_ACTION2_VAL+x} ] && [[ "$mfa_ct" -lt "$api_call_retry_limit" ]]; then
        sms_action
    else
        echo "Demo_Passwordless_SMS_Login_Policy action could not be set, exiting script."
        exit 1
    fi
    }

    #call the functions
    def_pop_id

    #script finish
    echo "------ End of Authentication Policy set for CIAM ------"

    echo "------ Beginning of Branding Theme set for CIAM ------"

    create_focus_ct=0
    create_slate_ct=0
    create_mural_ct=0
    create_split_ct=0

    function create_focus() {
        # create Ping Focus theme
        CREATE_FOCUS_THEME=$(curl -s --write-out "%{http_code}\n" --location --request POST "$API_LOCATION/environments/$ENV_ID/themes" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
        --header 'Content-Type: application/json' \
        --data-raw '{
            "template": "focus",
            "configuration": {
                "logoType": "IMAGE",
                "logo": {
                    "href": "https://d3uinntk0mqu3p.cloudfront.net/branding/market/a3d073bc-3108-49ad-b96c-404bea59a1d0.png",
                    "id": "00000000-0000-0000-0000-000000000000"
                },
                "backgroundColor": "#ededed",
                "backgroundType": "COLOR",
                "bodyTextColor": "#4a4a4a",
                "cardColor": "#fcfcfc",
                "headingTextColor": "#cb0020",
                "linkTextColor": "#2996cc",
                "buttonColor": "#cb0020",
                "buttonTextColor": "#ffffff",
                "name": "Ping Focus",
                "footer": "Experience sweet, secure digital experiences."
            }
        }')

        create_focus_ct=$((create_focus_ct+1))

        # checks theme created, as well as verify expected theme name to ensure creation
        CREATE_FOCUS_THEME_RESULT=$(echo $CREATE_FOCUS_THEME | sed 's@.*}@@')
        if [ $CREATE_FOCUS_THEME_RESULT == "200" ] ; then

            CHECK_FOCUS_THEME_CONTENT=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/themes" \
            --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.themes[] | select(.template=="focus") | .configuration.name')

            if [ "$CHECK_FOCUS_THEME_CONTENT" == "Ping Focus" ]; then
                echo "Ping Focus theme added and verified content..."
            else
                echo "Ping Focus theme added, however unable to verified content!"
            fi
        #if we're under the limit and it wasn't successful, retry.
        elif [[ "$CREATE_FOCUS_THEME_RESULT" != "200" ]] && [[ "$create_focus_ct" -lt "$api_call_retry_limit" ]]; then
            #rerun this
            create_focus
        else
            echo "Ping Focus theme NOT added!"
            exit 1
        fi
    }

    function create_slate() {
        # create Ping Slate theme
        CREATE_SLATE_THEME=$(curl -s --write-out "%{http_code}\n" --location --request POST "$API_LOCATION/environments/$ENV_ID/themes" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
        --header 'Content-Type: application/json' \
        --data-raw '{
            "template": "slate",
            "configuration": {
                "logoType": "IMAGE",
                "logo": {
                    "href": "https://d3uinntk0mqu3p.cloudfront.net/branding/market/a3d073bc-3108-49ad-b96c-404bea59a1d0.png",
                    "id": "00000000-0000-0000-0000-000000000000"
                },
                "backgroundColor": "",
                "backgroundType": "DEFAULT",
                "bodyTextColor": "#4C4C4C",
                "cardColor": "#FFFFFF",
                "headingTextColor": "#4A4A4A",
                "linkTextColor": "#5F5F5F",
                "buttonColor": "#4A4A4A",
                "buttonTextColor": "#FFFFFF",
                "name": "Ping Slate",
                "footer": "Experience sweet, secure digital experiences."
            }
        }')

        create_slate_ct=$((create_slate_ct+1))

        # checks theme created, as well as verify expected theme name to ensure creation
        CREATE_SLATE_THEME_RESULT=$(echo $CREATE_SLATE_THEME | sed 's@.*}@@')
        if [ $CREATE_SLATE_THEME_RESULT == "200" ] ; then

            CHECK_SLATE_THEME_CONTENT=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/themes" \
            --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.themes[] | select(.template=="slate") | .configuration.name')

            if [ "$CHECK_SLATE_THEME_CONTENT" == "Ping Slate" ]; then
                echo "Ping Slate theme added and verified content..."
            else
                echo "Ping Slate theme added, however unable to verified content!"
            fi
        #if we're under the limit and it wasn't successful, retry.
        elif [[ "$CREATE_SLATE_THEME_RESULT" != "200" ]] && [[ "$create_slate_ct" -lt "$api_call_retry_limit" ]]; then
            create_slate
        else
            echo "Ping Slate theme NOT added!"
            exit 1
        fi
    }

    function create_mural() {
        # create Ping Mural theme
        CREATE_MURAL_THEME=$(curl -s --write-out "%{http_code}\n" --location --request POST "$API_LOCATION/environments/$ENV_ID/themes" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
        --header 'Content-Type: application/json' \
        --data-raw '{
            "template": "mural",
            "configuration": {
                "logoType": "IMAGE",
                "logo": {
                    "href": "https://d3uinntk0mqu3p.cloudfront.net/branding/market/a3d073bc-3108-49ad-b96c-404bea59a1d0.png",
                    "id": "00000000-0000-0000-0000-000000000000"
                },
                "backgroundColor": "",
                "backgroundType": "DEFAULT",
                "bodyTextColor": "#000000",
                "cardColor": "#fcfcfc",
                "headingTextColor": "#000000",
                "linkTextColor": "#2996cc",
                "buttonColor": "#61b375",
                "buttonTextColor": "#ffffff",
                "name": "Ping Mural",
                "footer": "Experience sweet, secure digital experiences."
            }
        }')

        create_mural_ct=$((create_mural_ct+1))

        # checks theme created, as well as verify expected theme name to ensure creation
        CREATE_MURAL_THEME_RESULT=$(echo $CREATE_MURAL_THEME | sed 's@.*}@@')
        if [ $CREATE_MURAL_THEME_RESULT == "200" ] ; then

            CHECK_MURAL_THEME_CONTENT=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/themes" \
            --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.themes[] | select(.template=="mural") | .configuration.name')

            if [ "$CHECK_MURAL_THEME_CONTENT" == "Ping Mural" ]; then
                echo "Ping Mural theme added and verified content..."
            else
                echo "Ping Mural theme added, however unable to verified content!"
            fi
        #if we're under the limit and it wasn't successful, retry.
        elif [[ "$CREATE_MURAL_THEME_RESULT" != "200" ]] && [[ "$create_mural_ct" -lt "$api_call_retry_limit" ]]; then
            create_mural
        else
            echo "Ping Mural theme NOT added!"
            exit 1
        fi
    }

    function create_split() {
        # create Ping Split theme
        CREATE_SPLIT_THEME=$(curl -s --write-out "%{http_code}\n" --location --request POST "$API_LOCATION/environments/$ENV_ID/themes" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
        --header 'Content-Type: application/json' \
        --data-raw '{
            "template": "split",
            "configuration": {
                "logoType": "IMAGE",
                "logo": {
                    "href": "https://d3uinntk0mqu3p.cloudfront.net/branding/market/a3d073bc-3108-49ad-b96c-404bea59a1d0.png",
                    "id": "00000000-0000-0000-0000-000000000000"
                },
                "backgroundColor": "#263956",
                "backgroundType": "COLOR",
                "bodyTextColor": "#263956",
                "cardColor": "#fcfcfc",
                "headingTextColor": "#686f77",
                "linkTextColor": "#263956",
                "buttonColor": "#263956",
                "buttonTextColor": "#ffffff",
                "name": "Ping Split",
                "footer": "Experience sweet, secure digital experiences."
            }
        }')

        create_split_ct=$((create_split_ct+1))

        # checks theme created, as well as verify expected theme name to ensure creation
        CREATE_SPLIT_THEME_RESULT=$(echo $CREATE_SPLIT_THEME | sed 's@.*}@@')
        if [ $CREATE_SPLIT_THEME_RESULT == "200" ] ; then

            CHECK_SPLIT_THEME_CONTENT=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/themes" \
            --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.themes[] | select(.template=="split") | .configuration.name')

            if [ "$CHECK_SPLIT_THEME_CONTENT" == "Ping Split" ]; then
                echo "Ping Split theme added and verified content..."
            else
                echo "Ping Split theme added, however unable to verified content!"
            fi
        #if we're under the limit and it wasn't successful, retry.
        elif [[ "$CREATE_SPLIT_THEME_RESULT" != "200" ]] && [[ "$create_split_ct" -lt "$api_call_retry_limit" ]]; then
            create_split
        else
            echo "Ping Split theme NOT added!"
            exit 1
        fi
    }

    # check if themes exist. if they don't, create them
    theme_try=0
    function get_themes() {
        THEMES=$(curl -s --write-out "%{http_code}\n" --location --request GET "$API_LOCATION/environments/$ENV_ID/themes" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN")

        # checks theme created, as well as verify expected theme name to ensure creation
        THEMES_RESULT=$(echo $THEMES | sed 's@.*}@@')
        THEMES_CONTENT=$(echo $THEMES | sed -e 's/}[0-9][0-9][0-9]/}/g')

        if [[ "$THEMES_RESULT" == "200" ]] && [[ "$theme_try" -lt "$api_call_retry_limit" ]]; then
            CHECK_SLATE_THEME_CONTENT=$(echo "$THEMES_CONTENT" | jq -rc '._embedded.themes[] | select(.template=="slate") | .configuration.name')
            if [[ -z ${CHECK_SLATE_THEME_CONTENT+x} ]] || [[ "$CHECK_SLATE_THEME_CONTENT" != *"Ping Slate"* ]] ; then
                echo "Ping Slate Template does not currently exist. Creating now..."
                create_slate
            elif [[ "$CHECK_SLATE_THEME_CONTENT" == *"Ping Slate"* ]]; then
                echo "Ping Slate template already exists!"
            fi

            CHECK_SPLIT_THEME_CONTENT=$(echo "$THEMES_CONTENT"  | jq -rc '._embedded.themes[] | select(.template=="split") | .configuration.name')
            if [[ -z ${CHECK_SPLIT_THEME_CONTENT+x} ]] || [[ "$CHECK_SPLIT_THEME_CONTENT" != *"Ping Split"* ]] ; then
                echo "Ping Split Template does not currently exist. Creating now..."
                create_split
            elif [[ "$CHECK_SPLIT_THEME_CONTENT" == *"Ping Split"* ]]; then
                echo "Ping Split template already exists!"
            fi

            CHECK_MURAL_THEME_CONTENT=$(echo "$THEMES_CONTENT"  | jq -rc '._embedded.themes[] | select(.template=="mural") | .configuration.name')
            if [[ -z ${CHECK_MURAL_THEME_CONTENT+x} ]] || [[ "$CHECK_MURAL_THEME_CONTENT" != *"Ping Mural"* ]] ; then
                echo "Ping Mural Template does not currently exist. Creating now..."
                create_mural
            elif [[ "$CHECK_MURAL_THEME_CONTENT" == *"Ping Mural"* ]]; then
                echo "Ping Mural template already exists!"
            fi

            CHECK_FOCUS_THEME_CONTENT=$(echo "$THEMES_CONTENT"  | jq -rc '._embedded.themes[] | select(.template=="focus") | .configuration.name')
            if [[ -z ${CHECK_FOCUS_THEME_CONTENT+x} ]] || [[ "$CHECK_FOCUS_THEME_CONTENT" != *"Ping Focus"* ]] ; then
                echo "Ping Focus Template does not currently exist. Creating now..."
                create_focus
            elif [[ "$CHECK_FOCUS_THEME_CONTENT" == *"Ping Focus"* ]]; then
                echo "Ping Focus template already exists!"
            fi

        elif [[ "$THEMES_RESULT" != "200" ]] && [[ "$theme_try" -lt "$api_call_retry_limit" ]]; then
            theme_tries_left=$((api_call_retry_limit-theme_try))
            echo "Unable to get themes, retrying $theme_tries_left more time(s)..."
            theme_try=$((theme_try+1))
            get_themes
        else
            echo "Unable to get themes and exceeded try limit!"
            exit 1
        fi
    }

    get_themes

    echo "------ End of Branding Theme set for CIAM ------"

    echo "------ Beginning of Sample App Creation set for CIAM ------"

    ################## Get certificate signing key ID to assign to all applications ##################
    signing_key_id_try=0

    function assign_signing_cert_id() {
        # checks cert is present
        SIGNING_CERT_KEYS_RESULT=$(echo $SIGNING_CERT_KEYS | sed 's@.*}@@')
        if [[ "$SIGNING_CERT_KEYS_RESULT" == "200" ]] && [[ "$signing_key_id_try" -lt "$api_call_retry_limit" ]] ; then
            echo "Signing certificate key available, getting ID for signing certificate type..."
            # get signing cert id
            SIGNING_KEY_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/keys" \
            --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.keys[] | select(.usageType=="SIGNING") | .id')
            if [ -z "$SIGNING_KEY_ID" ]; then
                echo "Unable to get signing certificate ID, retrying..."
                check_signing_cert_keys
            else
                echo "Signing certificate key ID set, proceeding..."
            fi
        elif [[ $SIGNING_CERT_KEYS_RESULT != "200" ]] && [[ "$signing_key_id_try" -lt "$api_call_retry_limit" ]]; then
            signing_key_id_try=$((api_call_retry_limit-signing_key_id_try))
            echo "Unable to retrieve signing certificate key! Retrying $signing_key_id_try more time(s)..."
            signing_key_id_try=$((signing_key_id_try+1))
            check_signing_cert_keys
        else
            echo "Unable to successfully retrieve a signing certificate key and exceeded try limit!"
            echo "This must succeed before running additional tasks, exiting..."
            exit 1
        fi
    }

    function check_signing_cert_keys() {
        SIGNING_CERT_KEYS=$(curl -s --write-out "%{http_code}\n" --location --request GET "$API_LOCATION/environments/$ENV_ID/keys" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN")
        assign_signing_cert_id
    }

    check_signing_cert_keys

    ################## Create Demo App - Self-Service Registration ##################
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

        # checks app created, as well as verify expected app name to ensure creation
        CREATE_SSR_APP_RESULT=$(echo $CREATE_SSR_APP | sed 's@.*}@@')
        if [ $CREATE_SSR_APP_RESULT == "201" ]; then
            echo "Self-Service Registration demo app added, beginning content check..."
            check_ssr_app_content
        elif [[ $CREATE_SSR_APP_RESULT != "201" ]] && [[ "$ssr_app_try" -lt "$api_call_retry_limit" ]]; then
            ssr_app_try=$((ssr_app_try+1))
            echo "Self-Service Registration demo app NOT added! Checking app existence..."
            check_ssr_app_content
        else
            echo "Self-Service Registration demo app does NOT exist and attempts to create exceeded!"
            exit 1
        fi
    }

    # call create self-service registration app function above
    create_ssr_app

    ################## Create Demo App - Passwordless Login SMS Only ##################
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

        # checks app created, as well as verify expected app name to ensure creation
        CREATE_SMS_APP_RESULT=$(echo $CREATE_SMS_APP | sed 's@.*}@@')
        if [ $CREATE_SMS_APP_RESULT == "201" ] ; then
            echo "Passwordless Login SMS Only app added, beginning content check..."
            check_sms_app_content
        elif [[ $CREATE_SMS_APP_RESULT != "201" ]] && [[ "$sms_app_try" -lt "$api_call_retry_limit" ]]; then
            sms_app_try=$((sms_app_try+1))
            echo "Passwordless Login SMS Only app NOT added! Checking app existence..."
            check_sms_app_content
        else
            echo "Passwordless Login SMS Only app does NOT exist and attempts to create exceeded!"
            exit 1
        fi
    }
    # call create sms passwordless app function above
    create_sms_app

    ################## Create Demo App - Passwordless Login Any Method ##################
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

        # checks app created, as well as verify expected app name to ensure creation
        CREATE_PWDLESS_APP_RESULT=$(echo $CREATE_PWDLESS_APP | sed 's@.*}@@')
        if [ $CREATE_PWDLESS_APP_RESULT == "201" ] ; then
            echo "Passwordless Login Any Method app added, beginning content check..."
            check_pwdless_app_content
        elif [[ $CREATE_PWDLESS_APP_RESULT != "201" ]] && [[ "$pwdless_app_try" -lt "$api_call_retry_limit" ]]; then
            pwdless_app_try=$((pwdless_app_try+1))
            echo "Passwordless Login Any Method app NOT added! Checking app existence..."
            check_pwdless_app_content
        else
            echo "Passwordless Login Any Method app does NOT exist and attempts to create exceeded!"
            exit 1
        fi
    }
    # call create passwordless app function above
    create_pwdless_app

    echo "------ End of Sample App Creation set for CIAM ------"

    echo "------ Beginning of Sample App Policy Assignment set for CIAM ------"

    ################## Assign Self-Registration_Login_Policy to Self-Service Registration App ##################
    self_pol_id_try=0

    function assign_ssr_policy_id() {
        # checks policies are present
        POLS_RESULT=$(echo $POLS | sed 's@.*}@@')
        if [ "$POLS_RESULT" == "200" ]; then
            echo "Sign on policies available, getting ID for Self-Registration_Login_Policy..."
            # get policy id
            SELF_POL_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
            --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
            | jq -rc '._embedded.signOnPolicies[] | select(.name=="Demo_Self-Registration_Login_Policy") | .id')
            if [[ -z "$SELF_POL_ID" ]] || [[ "$SELF_POL_ID" == "" ]] ; then
                echo "Could not locate Self-Registration_Login_Policy ID, retrying..."
                check_policies_for_ssr
            else
                echo "Self-Registration_Login_Policy ID set, proceeding..."
            fi
        elif [[ $POLS_RESULT != "200" ]] && [[ "$self_pol_id_try" -lt "$api_call_retry_limit" ]] ; then
            self_pol_id_tries=$((api_call_retry_limit-self_pol_id_try))
            echo "Unable to retrieve Self-Registration_Login_Policy! Retrying $self_pol_id_tries more time(s)..."
            self_pol_id_try=$((self_pol_id_try+1))
            check_policies_for_ssr
        else
            echo "Unable to successfully retrieve Self-Registration_Login_Policy and exceeded try limit!"
            exit 1
        fi
    }

    function check_policies_for_ssr() {
        POLS=$(curl -s --write-out "%{http_code}\n" --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN")
        assign_ssr_policy_id
    }
    check_policies_for_ssr

    ### Assign Self-Service Registration App ID ###
    ssr_app_try=0
    ssr_app_pol_try=0
    ssr_app_content_try=0

    function check_ssr_app_content() {
        # set app ID variable
        SSR_APP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select(.name=="Demo App - Self-Service Registration") | .id')
        if [[ -z "$SSR_APP_ID" ]] || [[ "$SSR_APP_ID" == "" ]] ; then
            ssr_app_content_tries=$((api_call_retry_limit-ssr_app_content_try))
            echo "Self-Service Registration ID not found. Retrying $ssr_app_content_tries more time(s)..."
            ssr_app_content_try=$((ssr_app_content_try+1))
            check_ssr_app_content
        elif [[ "$ssr_app_content_try" -lt "$api_call_retry_limit" ]] ; then
            # check policy ID matches the ID of the auth policy
            SELF_POL_SOA_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications/$SSR_APP_ID/signOnPolicyAssignments" \
            --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
            | jq -rc '._embedded.signOnPolicyAssignments[].signOnPolicy.id')

            if [ "$SELF_POL_ID" == "$SELF_POL_SOA_ID" ]; then
                echo "Self-Service Registration App assignment to Demo_Self-Registration_Login_Policy verified..."
            else
                ssr_app_content_tries=$((api_call_retry_limit-ssr_app_content_try))
                echo "Self-Service Registration App assignment to Demo_Self-Registration_Login_Policy NOT verified! Retrying $ssr_app_content_tries more time(s)..."
                ssr_app_content_try=$((ssr_app_content_try+1))
                assign_ssr_app
            fi
        fi
    }

    function assign_ssr_app() {
        # checks app is present
        APPS_RESULT=$(echo $APPS | sed 's@.*}@@')
        if [[ "$APPS_RESULT" == "200" ]] && [[ "$ssr_app_try" -lt "$api_call_retry_limit" ]] && [[ "$ssr_app_pol_try" -lt "$api_call_retry_limit" ]] ; then
            echo "Applications available, getting Self-Service Registration App ID..."
            # get ssr app id
            SSR_APP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
            --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select(.name=="Demo App - Self-Service Registration") | .id')
            if [[ -z "$SSR_APP_ID" ]] || [[ "$SSR_APP_ID" == "" ]] ; then
                echo "Unable to retrieve Self-Service Registration App, retrying..."
                check_apps_for_ssr
            else
                echo "Self-Service Registration App ID found and set, proceeding..."
                # Assign Self-Service Registration App to Self-Registration_Login_Policy policy
                ASSIGN_SSR_APP_POL=$(curl -s --write-out "%{http_code}\n" --location --request POST "$API_LOCATION/environments/$ENV_ID/applications/$SSR_APP_ID/signOnPolicyAssignments" \
                --header 'Content-Type: application/json' \
                --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
                --data-raw '{
                    "priority": 1,
                    "signOnPolicy": {
                        "id": "'"$SELF_POL_ID"'"
                    }
                }')
                # verify app auth policy assigned
                ASSIGN_SSR_APP_POL_RESULT=$(echo $ASSIGN_SSR_APP_POL | sed 's@.*}@@')
                if [ "$ASSIGN_SSR_APP_POL_RESULT" == "201" ]; then
                    echo "Self-Service Registration App to Self-Registration_Login_Policy assigned successfully, verifying content..."
                    check_ssr_app_content
                else
                    ssr_app_pol_tries=$((api_call_retry_limit-ssr_app_pol_try))
                    echo "Self-Service Registration App to Self-Registration_Login_Policy NOT assigned successfully! Checking to see if this is already in place..."
                    ssr_app_pol_try=$((ssr_app_pol_try+1))
                    check_ssr_app_content
                fi
            fi
        elif [[ $APPS_RESULT != "200" ]] && [[ "$ssr_app_try" -lt "$api_call_retry_limit" ]] ; then
            ssr_app_tries=$((api_call_retry_limit-ssr_app_try))
            echo "Unable to retrieve applications! Retrying $ssr_app_tries more time(s)..."
            ssr_app_try=$((ssr_app_try+1))
            check_apps_for_ssr
        else
            echo "Unable to successfully retrieve applications and exceeded try limit!"
            exit 1
        fi
    }

    function check_apps_for_ssr() {
        APPS=$(curl -s --write-out "%{http_code}\n" --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN")
        assign_ssr_app
    }
    check_apps_for_ssr

    ################## Assign Demo_Passwordless_SMS_Login_Policy to Passwordless Login SMS Only App ##################
    sms_pol_id_try=0

    function assign_sms_policy_id() {
        # checks policies are present
        POLS_RESULT=$(echo $POLS | sed 's@.*}@@')
        if [ "$POLS_RESULT" == "200" ]; then
            echo "Sign on policies available, getting ID for Demo_Passwordless_SMS_Login_Policy..."
            # get SMS policy id
            SMS_POL_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
            --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
            | jq -rc '._embedded.signOnPolicies[] | select(.name=="Demo_Passwordless_SMS_Login_Policy") | .id')
            if [[ -z "$SELF_POL_ID" ]] || [[ "$SELF_POL_ID" == "" ]] ; then
                echo "Could not locate Demo_Passwordless_SMS_Login_Policy ID, retrying..."
                check_policies_for_sms
            else
                echo "Demo_Passwordless_SMS_Login_Policy ID set, proceeding..."
            fi
        elif [[ $POLS_RESULT != "200" ]] && [[ "$sms_pol_id_try" -lt "$api_call_retry_limit" ]] ; then
            sms_pol_id_tries=$((api_call_retry_limit-sms_pol_id_try))
            echo "Unable to retrieve Demo_Passwordless_SMS_Login_Policy! Retrying $sms_pol_id_tries more time(s)..."
            sms_pol_id_try=$((sms_pol_id_try+1))
            check_policies_for_sms
        else
            echo "Unable to successfully retrieve Demo_Passwordless_SMS_Login_Policy and exceeded try limit!"
            exit 1
        fi
    }

    function check_policies_for_sms() {
        POLS=$(curl -s --write-out "%{http_code}\n" --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN")
        assign_sms_policy_id
    }
    check_policies_for_sms

    ### Assign SMS App to SMS Policy ###
    sms_app_try=0
    sms_app_pol_try=0
    sms_app_content_try=0

    function check_sms_app_content() {
        # get sms app id
            SMS_APP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
            --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select(.name=="Demo App - Passwordless Login SMS Only") | .id')
        if [[ -z "$SSR_APP_ID" ]] || [[ "$SSR_APP_ID" == "" ]] ; then
            sms_app_content_tries=$((api_call_retry_limit-sms_app_content_try))
            echo "Passwordless Login SMS Only ID not found. Retrying $sms_app_content_tries more time(s)..."
            sms_app_content_try=$((sms_app_content_try+1))
            check_sms_app_content
        elif [[ "$sms_app_content_try" -lt "$api_call_retry_limit" ]] ; then
            # check policy ID matches the ID of the auth policy
            SMS_POL_SOA_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications/$SMS_APP_ID/signOnPolicyAssignments" \
            --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
            | jq -rc '._embedded.signOnPolicyAssignments[].signOnPolicy.id')

            if [ "$SMS_POL_ID" == "$SMS_POL_SOA_ID" ]; then
                echo "Passwordless Login SMS Only App assignment to Demo_Passwordless_SMS_Login_Policy verified..."
            else
                sms_app_content_tries=$((api_call_retry_limit-sms_app_content_try))
                echo "Passwordless Login SMS Only App assignment to Demo_Passwordless_SMS_Login_Policy NOT verified! Retrying $sms_app_content_tries more time(s)..."
                sms_app_content_try=$((sms_app_content_try+1))
                assign_sms_app
            fi
        fi
    }

    function assign_sms_app() {
        # checks app is present
        APPS_RESULT=$(echo $APPS | sed 's@.*}@@')
        if [[ "$APPS_RESULT" == "200" ]] && [[ "$sms_app_try" -lt "$api_call_retry_limit" ]] && [[ "$sms_app_pol_try" -lt "$api_call_retry_limit" ]] ; then
            echo "Applications available, getting Passwordless Login SMS Only App ID..."
            # get sms app id
            SMS_APP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
            --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select(.name=="Demo App - Passwordless Login SMS Only") | .id')
            if [[ -z "$SMS_APP_ID" ]] || [[ "$SMS_APP_ID" == "" ]] ; then
                echo "Unable to retrieve Passwordless Login SMS Only App, retrying..."
                check_apps
            else
                echo "Passwordless Login SMS Only App ID found and set, proceeding..."
                ASSIGN_SMS_APP_POL=$(curl -s --write-out "%{http_code}\n" --location --request POST "$API_LOCATION/environments/$ENV_ID/applications/$SMS_APP_ID/signOnPolicyAssignments" \
                --header 'Content-Type: application/json' \
                --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
                --data-raw '{
                    "priority": 1,
                    "signOnPolicy": {
                        "id": "'"$SMS_POL_ID"'"
                    }
                }')
                # verify app auth policy assigned
                ASSIGN_SMS_APP_POL_RESULT=$(echo $ASSIGN_SMS_APP_POL | sed 's@.*}@@')
                if [ "$ASSIGN_SMS_APP_POL_RESULT" == "201" ]; then
                    echo "Passwordless Login SMS Only App to Demo_Passwordless_SMS_Login_Policy assigned successfully, verifying content..."
                    check_ssr_app_content
                else
                    sms_app_pol_tries=$((api_call_retry_limit-sms_app_pol_try))
                    echo "Passwordless Login SMS Only App to Demo_Passwordless_SMS_Login_Policy NOT assigned successfully! Checking to see if this is already in place..."
                    sms_app_pol_try=$((sms_app_pol_try+1))
                    check_sms_app_content
                fi
            fi
        elif [[ $APPS_RESULT != "200" ]] && [[ "$sms_app_try" -lt "$api_call_retry_limit" ]] ; then
            sms_app_tries=$((api_call_retry_limit-sms_app_try))
            echo "Unable to retrieve applications! Retrying $sms_app_tries more time(s)..."
            sms_app_try=$((sms_app_try+1))
            check_apps
        else
            echo "Unable to successfully retrieve applications and exceeded try limit!"
            exit 1
        fi
    }

    function check_apps_for_sms() {
        APPS=$(curl -s --write-out "%{http_code}\n" --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN")
        assign_sms_app
    }
    check_apps_for_sms

    ################## Assign Demo_Passwordless_Any_Method_Login_Policy to Passwordless Login Any Method ##################
    mfa_pol_id_try=0

    function assign_mfa_policy_id() {
        # checks policies are present
        POLS_RESULT=$(echo $POLS | sed 's@.*}@@')
        if [ "$POLS_RESULT" == "200" ]; then
            echo "Sign on policies available, getting ID for Demo_Passwordless_Any_Method_Login_Policy..."
            # get all mfa policy id
            ALL_MFA_POL_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
            --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
            | jq -rc '._embedded.signOnPolicies[] | select(.name=="Demo_Passwordless_Any_Method_Login_Policy") | .id')
            if [[ -z "$ALL_MFA_POL_ID" ]] || [[ "$ALL_MFA_POL_ID" == "" ]] ; then
                echo "Could not locate Demo_Passwordless_Any_Method_Login_Policy ID, retrying..."
                check_policies_for_mfa
            else
                echo "Demo_Passwordless_Any_Method_Login_Policy ID set, proceeding..."
            fi
        elif [[ $POLS_RESULT != "200" ]] && [[ "$mfa_pol_id_try" -lt "$api_call_retry_limit" ]] ; then
            mfa_pol_id_tries=$((api_call_retry_limit-mfa_pol_id_try))
            echo "Unable to retrieve policies! Retrying $mfa_pol_id_tries more time(s)..."
            mfa_pol_id_try=$((mfa_pol_id_try+1))
            check_policies_for_mfa
        else
            echo "Unable to successfully retrieve policies and exceeded try limit!"
            exit 1
        fi
    }

    function check_policies_for_mfa() {
        POLS=$(curl -s --write-out "%{http_code}\n" --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN")
        assign_mfa_policy_id
    }
    check_policies_for_mfa

    ### Assign MFA App to MFA Policy ###
    mfa_app_try=0
    mfa_app_pol_try=0
    mfa_app_content_try=0

    function check_mfa_app_content() {
        # set app ID variable
        MFA_APP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select(.name=="Demo App - Passwordless Login Any Method") | .id')
        if [[ -z "$MFA_APP_ID" ]] || [[ "$MFA_APP_ID" == "" ]] ; then
            ssr_app_content_tries=$((api_call_retry_limit-mfa_app_content_try))
            echo "Passwordless Login Any Method ID not found. Retrying $ssr_app_content_tries more time(s)..."
            mfa_app_content_try=$((mfa_app_content_try+1))
            check_mfa_app_content
        elif [[ "$mfa_app_content_try" -lt "$api_call_retry_limit" ]] ; then
            # check policy ID matches the ID of the auth policy
            MFA_POL_SOA_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications/$MFA_APP_ID/signOnPolicyAssignments" \
            --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
            | jq -rc '._embedded.signOnPolicyAssignments[].signOnPolicy.id')

            if [ "$ALL_MFA_POL_ID" == "$MFA_POL_SOA_ID" ]; then
                echo "Passwordless Login Any Method App assignment to Demo_Passwordless_Any_Method_Login_Policy verified..."
            else
                mfa_app_content_tries=$((api_call_retry_limit-mfa_app_content_try))
                echo "Passwordless Login Any Method App assignment to Demo_Passwordless_Any_Method_Login_Policy NOT verified! Retrying $mfa_app_content_tries more time(s)..."
                mfa_app_content_try=$((mfa_app_content_try+1))
                assign_mfa_app
            fi
        fi
    }

    function assign_mfa_app() {
        # checks app is present
        APPS_RESULT=$(echo $APPS | sed 's@.*}@@')
        if [[ "$APPS_RESULT" == "200" ]] && [[ "$mfa_app_try" -lt "$api_call_retry_limit" ]] && [[ "$mfa_app_pol_try" -lt "$api_call_retry_limit" ]] ; then
            echo "Applications available, getting Passwordless Login Any Method App ID..."
            # get sms app id
            MFA_APP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
            --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select(.name=="Demo App - Passwordless Login Any Method") | .id')
            if [[ -z "$SMS_APP_ID" ]] || [[ "$SMS_APP_ID" == "" ]] ; then
                echo "Unable to retrieve Passwordless Login Any Method App, retrying..."
                check_apps_for_mfa
            else
                echo "Passwordless Login Any Method App ID found and set, proceeding..."
                ASSIGN_MFA_APP_POL=$(curl -s --write-out "%{http_code}\n" --location --request POST "$API_LOCATION/environments/$ENV_ID/applications/$MFA_APP_ID/signOnPolicyAssignments" \
                --header 'Content-Type: application/json' \
                --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
                --data-raw '{
                    "priority": 1,
                    "signOnPolicy": {
                        "id": "'"$ALL_MFA_POL_ID"'"
                    }
                }')
                # verify app auth policy assigned
                ASSIGN_MFA_APP_POL_RESULT=$(echo $ASSIGN_MFA_APP_POL | sed 's@.*}@@')
                if [ "$ASSIGN_MFA_APP_POL_RESULT" == "201" ]; then
                    echo "Passwordless Login Any Method App to Demo_Passwordless_Any_Method_Login_Policy assigned successfully, verifying content..."
                    check_mfa_app_content
                else
                    mfa_app_pol_tries=$((api_call_retry_limit-mfa_app_pol_try))
                    echo "Passwordless Login Any Method App to Demo_Passwordless_Any_Method_Login_Policy NOT assigned successfully! Checking to see if this is already in place..."
                    mfa_app_pol_try=$((mfa_app_pol_try+1))
                    check_mfa_app_content
                fi
            fi
        elif [[ $ASSIGN_MFA_APP_POL_RESULT != "200" ]] && [[ "$mfa_app_try" -lt "$api_call_retry_limit" ]] ; then
            mfa_app_tries=$((api_call_retry_limit-mfa_app_try))
            echo "Unable to retrieve applications! Retrying $mfa_app_tries more time(s)..."
            mfa_app_try=$((mfa_app_try+1))
            check_apps_for_mfa
        else
            echo "Unable to successfully retrieve applications and exceeded try limit!"
            exit 1
        fi
    }

    function check_apps_for_mfa() {
        APPS=$(curl -s --write-out "%{http_code}\n" --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN")
        assign_mfa_app
    }
    check_apps_for_mfa

    echo "------ End of Sample App Policy Assignment set for CIAM ------"

    echo "###### COMPLETED CIAM SOLUTIONS PRE-CONFIG TASKS ######"
}

function workforce() {

    # set global api call retry limit - this can be set to desired amount, default is 2
    api_call_retry_limit=1

    echo "------ Beginning Risk Policy Set for WF ------"

    risk_pol_set=0

    function check_risk_policy() {
        # validate expected risk policy name change
        RISK_POL_STATUS=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/riskPolicySets" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
        | jq -rc '._embedded.riskPolicySets[]  | select(.name=="Default Workforce High Risk Policy") | .name')

        # check expected name from config change
        if [ "$RISK_POL_STATUS" = "Default Workforce High Risk Policy" ] && [[ "$risk_pol_set" -lt "$api_call_retry_limit" ]]; then
            echo "Verified Default Workforce High Risk Policy set successfully..."
        elif [ "$RISK_POL_STATUS" != "Default Workforce High Risk Policy" ] && [[ "$risk_pol_set" -lt "$api_call_retry_limit" ]]; then
            #put a stop to the madness (potentially) by incrementing the total limit
            risk_pol_set=$((risk_pol_set+1))
            set_risk_policy
        else
            echo "Default Workforce High Risk Policy NOT set successfully!"
            exit 1
        fi
    }

    function set_risk_policy() {
        # Get Current Default Risk Policy
        RISK_POL_SET_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/riskPolicySets" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.riskPolicySets[]  | select(.name=="Default Risk Policy") | .id')

        SET_RISK_POL_NAME=$(curl -s --write-out "%{http_code}\n" --location --request PUT "$API_LOCATION/environments/$ENV_ID/riskPolicySets/$RISK_POL_SET_ID" \
        --header 'Content-Type: application/json' \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
        --data-raw '{"name" : "Default Workforce High Risk Policy",
                "default" : true,
                "canUseIntelligenceDataConsent": true,
                "description" : "Workforce Risk Policy",
                "defaultResult" : {
                "level" : "LOW",
                "type" : "VALUE"
                },
                "riskPolicies" : [ {
                "name" : "GEOVELOCITY_ANOMALY",
                "priority" : 1,
                "result" : {
                    "level" : "HIGH",
                    "type" : "VALUE"
                },
                "condition" : {
                    "equals" : true,
                    "value" : "${details.impossibleTravel}"
                }
                },
                {
                "name" : "MEDIUM_WEIGHTED_POLICY",
                "priority" : 2,
                "result" : {
                    "level" : "MEDIUM",
                    "type" : "VALUE"
                },
                "condition" : {
                    "between" : {
                    "minScore" : 40,
                    "maxScore" : 70
                    },
                    "aggregatedWeights" : [ {
                    "value" : "${details.aggregatedWeights.anonymousNetwork}",
                    "weight" : 4
                    }, {
                    "value" : "${details.aggregatedWeights.geoVelocity}",
                    "weight" : 2
                    }, {
                    "value" : "${details.aggregatedWeights.ipRisk}",
                    "weight" : 5
                    }, {
                    "value" : "${details.aggregatedWeights.userRiskBehavior}",
                    "weight" : 10
                    } ]
                }
                },
                {
                "name" : "HIGH_WEIGHTED_POLICY",
                "priority" : 3,
                "result" : {
                    "level" : "HIGH",
                    "type" : "VALUE"
                },
                "condition" : {
                    "between" : {
                    "minScore" : 70,
                    "maxScore" : 100
                    },
                    "aggregatedWeights" : [ {
                    "value" : "${details.aggregatedWeights.anonymousNetwork}",
                    "weight" : 4
                    }, {
                    "value" : "${details.aggregatedWeights.geoVelocity}",
                    "weight" : 2
                    }, {
                    "value" : "${details.aggregatedWeights.ipRisk}",
                    "weight" : 5
                    }, {
                    "value" : "${details.aggregatedWeights.userRiskBehavior}",
                    "weight" : 10
                    } ]
                }
                } ]
        }')

        # check response code
        SET_RISK_POL_NAME_RESULT=$(echo $SET_RISK_POL_NAME | sed 's@.*}@@' )
        if [ "$SET_RISK_POL_NAME_RESULT" == "200" ] && [[ "$risk_pol_set" -lt "$api_call_retry_limit" ]]; then
            echo "Default Workforce High Risk Policy policy set, verifying content..."
            check_risk_policy
        elif [[ "$SET_RISK_POL_NAME_RESULT" != "200" ]] &&  [[ "$risk_pol_set" -lt "$api_call_retry_limit" ]]; then
            echo "Default Workforce High Risk Policy not set! Verifying content to see if already exists..."
            check_risk_policy
        else
            echo "Default Workforce High Risk Policy unable to be set!"
            exit 1
        fi
    }

    function check_risk_enabled() {
        #check if the environment is allowed to use Risk
        RISK_ENABLED=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/capabilities" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '.canUseIntelligenceRisk')

        if [[ $RISK_ENABLED == true ]]; then
            #let's do the rest of this
            set_risk_policy
        else
            echo "PingOne Risk Management is not enabled for this environment"
            exit 0
        fi
    }
    #check it's enabled (will attempt execute all functions if it is).
    check_risk_enabled

    #script finish
    echo "------ End of Risk Policy Set for WF ------"

    echo "------ Beginning of Password Policy Set for WF ------"

    pass_pol_set=0

    #check that things lookg accurate
    function check_password_policy() {
        if [ -z ${PASS_POL_SET+x} ] && [[ "$pass_pol_set" -lt "$api_call_retry_limit" ]]; then
            echo "Password policy ID not found, retrying"
            set_password_policy
        elif [ -z ${PASS_POL_SET+x} ] && [[ "$pass_pol_set" -ge "$api_call_retry_limit" ]]; then
            echo "Password policy ID not found, retry limit exceeded."
            exit 1
        else
            #check that it's set as expected
            PASS_POL_STATUS=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/passwordPolicies" \
            --header 'content-type: application/x-www-form-urlencoded' \
            --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
            | jq -rc '._embedded.passwordPolicies[] | select(.name=="Passphrase") | .default')

            #verify set true
            if [ "$PASS_POL_STATUS" = true ]; then
                echo "Passphrase policy set successfully..."
            else
                echo "Passphrase policy not set successfully!"
                exit 1
            fi
        fi
    }

    function set_password_policy() {
        #get the id modifying
        PASS_POL_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/passwordPolicies" \
        --header 'content-type: application/x-www-form-urlencoded' \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
        | jq -rc '._embedded.passwordPolicies[] | select(.name=="Passphrase") | .id')

        #set the change
        PASS_POL_SET=$(curl -s --location --request PUT "$API_LOCATION/environments/$ENV_ID/passwordPolicies/$PASS_POL_ID" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN " \
        --header 'Content-Type: application/json' \
        --data-raw '{
            "id" : "'"$PASS_POL_ID"'",
                "environment" : {
                "id" : "'"$ENV_ID"'"
                },
                "name" : "Passphrase",
                "description" : "A policy that encourages the use of passphrases",
                "excludesProfileData" : true,
                "notSimilarToCurrent" : true,
                "excludesCommonlyUsed" : true,
                "maxRepeatedCharacters": 2,
                "minComplexity" : 7,
                "maxAgeDays" : 182,
                "minAgeDays" : 1,
                "history" : {
                "count" : 6,
                "retentionDays" : 365
                },
                "length": {
                "min": 8,
                "max": 255
                },
                "lockout" : {
                "failureCount" : 5,
                "durationSeconds" : 900
                },
                "default" : true
            }')

        #put a stop to the madness (potentially) by incrementing the total limit
        pass_pol_set=$((pass_pol_set+1))

        #execute the function
        check_password_policy
    }

    #execute the function
    set_password_policy

    echo "------ End of Password Policy Set for WF ------"

    echo "------ Beginning User Populations for WF ------"

    # set global api call retry limit - this can be set to desired amount, default is 1
    api_call_retry_limit=1

    #cheating with user pop set because I was lazy with the function. Wanna give it the legit number of tries since the incremement is at the start.
    user_pop_set=0
    user_pop_get=0
    sample_set=0
    more_sample_set=0

    function get_user_pop_id() {
        # get Sample Users population name
        SAMPLE_USERS_POP=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Sample Users") | .name')

        # get More Sample Users population name
        MORE_SAMPLE_USERS_POP=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="More Sample Users") | .name')

        # get Employees population name
        EMPLOYEE_USERS_POP=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Employees") | .name')

        # get Contractors population name
        CONTRACTOR_USERS_POP=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Contractors") | .name')

        #if all right set variables and move on.
        if [[ "$SAMPLE_USERS_POP" == "Sample Users" ]] && [[ "$MORE_SAMPLE_USERS_POP" == "More Sample Users" ]]; then
            echo "Expected Populations found successfully..."
            SAMPLE_POPS[0]="$SAMPLE_USERS_POP"
            SAMPLE_POPS[1]="$MORE_SAMPLE_USERS_POP"
            #call the next function to do the work
            set_user_pop
        elif [[ "$EMPLOYEE_USERS_POP" == "Employees" ]] && [[ "$CONTRACTOR_USERS_POP" == "Contractors" ]]; then
            SAMPLE_POPS[0]="$EMPLOYEE_USERS_POP"
            SAMPLE_POPS[1]="$CONTRACTOR_USERS_POP"
            echo "Workforce use-case Employees and Contractors populations already exist..."
        else
            if [[ "$user_pop_set" -lt "$api_call_retry_limit" ]]; then
                echo "Sample Users population or More Sample Users population not found. Retrying."
                user_pop_set=$((user_pop_set+1))
                get_user_pop_id
            #out of tries and one or both not set
            else
                echo "One or both population(s) not found and number of allowed runs exceeded, exiting now."
                exit 1
            fi
        fi
    }

    function set_user_pop() {

        for SAMPLE_POP in "${SAMPLE_POPS[@]}"; do

            # check if name matches Sample Users population
            if [ "$SAMPLE_POP" == "Sample Users" ]; then

                # get sample users population ID
                SAMPLE_USERS_POP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
                --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Sample Users") | .id')

                if [[ -n "$SAMPLE_USERS_POP_ID" ]] && [[ $SAMPLE_USERS_POP_ID != 'null' ]] && [[ "$sample_set" -lt "$api_call_retry_limit" ]]; then
                    # update More Sample Users population to contractors
                    UPDATE_SAMPLE_USERS_POP=$(curl -s --write-out "%{http_code}\n" --location --request PUT "$API_LOCATION/environments/$ENV_ID/populations/$SAMPLE_USERS_POP_ID" \
                    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN"  --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
                    --header 'Content-Type: application/json' \
                    --data-raw '{
                        "name" : "Contractors",
                        "description" : "This is a sample contractor population."
                    }')

                    # check response code
                    UPDATE_SAMPLE_USERS_POP_RESULT=$(echo $UPDATE_SAMPLE_USERS_POP | sed 's@.*}@@' )
                    if [ "$UPDATE_SAMPLE_USERS_POP_RESULT" == "200" ] ; then

                        # check for new population name
                        SAMPLE_USERS_POP_NAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
                        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Contractors") | .name')

                        # check if new sample population matches expected name, verifying sucessful update
                        if [ "$SAMPLE_USERS_POP_NAME" == "Contractors" ]; then
                            echo "Sample Users population successfully updated to Contractors..."
                        else
                            echo "Sample Users population updated, however unable to verify new name change!"
                            get_user_pop_id
                        fi
                    fi
                #if unset or null, rerun if within limit
                elif ([ -z ${SAMPLE_USERS_POP_ID+x} ] || [[ "$SAMPLE_USERS_POP_ID" == 'null' ]]) \
                && [[ "$sample_set" -lt "$api_call_retry_limit" ]] && [[ "$User_pop_set" -lt "$api_call_retry_limit" ]]; then
                    #retry!
                    sample_set=$((sample_set+1))
                    set_user_pop
                #if unset, too many runs, or other problem we're quitting now.
                else
                    echo "Sample Users population not found and number of allowed runs exceeded, exiting now."
                    exit 1
                fi

            # check if name matches More Sample Users population
            elif [ "$SAMPLE_POP" == "More Sample Users" ]; then

                # get more sample users population ID
                MORE_SAMPLE_USERS_POP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
                --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="More Sample Users") | .id')

                if [[ -n "$MORE_SAMPLE_USERS_POP_ID" ]] && [[ $MORE_SAMPLE_USERS_POP_ID != 'null' ]] && [[ "$sample_set" -lt "$api_call_retry_limit" ]]; then
                    # create another sample group based on More Sample Users population
                    UPDATE_MORE_SAMPLE_USERS_POP=$(curl -s --write-out "%{http_code}\n" --location --request PUT "$API_LOCATION/environments/$ENV_ID/populations/$MORE_SAMPLE_USERS_POP_ID" \
                    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN"  --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
                    --header 'Content-Type: application/json' \
                    --data-raw '{
                        "name" : "Employees",
                        "description" : "This is a sample employee population."
                    }')

                    # check response code
                    UPDATE_MORE_SAMPLE_USERS_POP_RESULT=$(echo $UPDATE_MORE_SAMPLE_USERS_POP | sed 's@.*}@@' )
                    if [ "$UPDATE_MORE_SAMPLE_USERS_POP_RESULT" == "200" ] ; then

                        # check for new population name
                        MORE_SAMPLE_USERS_POP_NAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
                        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Employees") | .name')

                        # check if new sample population matches expected name, verifying sucessful update
                        if [ "$MORE_SAMPLE_USERS_POP_NAME" == "Employees" ]; then
                            echo "More Sample Users population successfully updated to Employees..."
                        else
                            echo "More Sample Users population updated, however unable to verify new name change!"
                            get_user_pop_id
                        fi
                    fi
                #if unset or null, rerun if within limit
                elif ([ -z ${MORE_SAMPLE_USERS_POP_NAME+x} ] || [[ "$MORE_SAMPLE_USERS_POP_NAME" == 'null' ]]) \
                && [[ "$more_sample_set" -lt "$api_call_retry_limit" ]] && [[ "$User_pop_set" -lt "$api_call_retry_limit" ]]; then
                    #retry!
                    more_sample_set=$((more_sample_set+1))
                    set_user_pop
                #if unset, too many runs, or other problem we're quitting now.
                else
                    echo "More Sample Users population not found and number of allowed runs exceeded, exiting now."
                    exit 1
                fi
            else
                echo "Sample Users population or More Sample Users population not found. Exiting..."
                exit 1
            fi
        done
    }

    #start all of this logic
    get_user_pop_id

    echo "------ End of User Populations Set for WF ------"

    echo "###### COMPLETED WF SOLUTIONS PRE-CONFIG TASKS ######"
}

function check_bom() {
    BOM=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/billOfMaterials" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '.products[].type')
    BOM_RESULT=$( echo "$BOM" | sed -e 's/ //g')
    if [[ "$BOM_RESULT" == *"PING_ONE_MFA"* ]]; then
        echo "Found PingOne MFA in Bill of Materials."
        echo "###### Executing CIAM pre-config tasks ######"
        ciam
    elif [[ "$BOM_RESULT" == *"PING_ID"* ]]; then
        echo "Found PingID in Bill of Materials."
        echo "#### Executing Workforce pre-config tasks ####"
        workforce
    else
        echo "Products found in the Bill of Materials are not compatible with Solutions pre-config..."
        exit 1
    fi
}

check_bom
