#!/bin/bash

# configure PingOne Sample SAML Apps for CIAM authentication policies

#Variables needed to be passed for this script:
# API_LOCATION
# ENV_ID
# WORKER_APP_ACCESS_TOKEN

echo "------ Beginning 601-sample_app_pol_set.sh ------"

# set global api call retry limit - this can be set to desired amount, default is 1
api_call_retry_limit=1

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
    elif [[ $POLS_RESULT != "200" ]] && [[ "$self_pol_id_try" < "$api_call_retry_limit" ]] ; then
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
    elif [[ "$ssr_app_content_try" < "$api_call_retry_limit" ]] ; then
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
    if [[ "$APPS_RESULT" == "200" ]] && [[ "$ssr_app_try" < "$api_call_retry_limit" ]] && [[ "$ssr_app_pol_try" < "$api_call_retry_limit" ]] ; then
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
    elif [[ $APPS_RESULT != "200" ]] && [[ "$ssr_app_try" < "$api_call_retry_limit" ]] ; then
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
    elif [[ $POLS_RESULT != "200" ]] && [[ "$sms_pol_id_try" < "$api_call_retry_limit" ]] ; then
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
    elif [[ "$sms_app_content_try" < "$api_call_retry_limit" ]] ; then
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
    if [[ "$APPS_RESULT" == "200" ]] && [[ "$sms_app_try" < "$api_call_retry_limit" ]] && [[ "$sms_app_pol_try" < "$api_call_retry_limit" ]] ; then
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
    elif [[ $APPS_RESULT != "200" ]] && [[ "$sms_app_try" < "$api_call_retry_limit" ]] ; then
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
    elif [[ $POLS_RESULT != "200" ]] && [[ "$mfa_pol_id_try" < "$api_call_retry_limit" ]] ; then
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
    elif [[ "$mfa_app_content_try" < "$api_call_retry_limit" ]] ; then
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
    if [[ "$APPS_RESULT" == "200" ]] && [[ "$mfa_app_try" < "$api_call_retry_limit" ]] && [[ "$mfa_app_pol_try" < "$api_call_retry_limit" ]] ; then
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
    elif [[ $ASSIGN_MFA_APP_POL_RESULT != "200" ]] && [[ "$mfa_app_try" < "$api_call_retry_limit" ]] ; then
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

echo "------ End of 601-sample_app_pol_set.sh ------"
