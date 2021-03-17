#!/bin/bash

# revert PingOne Sample SAML App authentication policy assignments for CIAM

#Variables needed to be passed for this script:
# API_LOCATION
# ENV_ID
# WORKER_APP_ACCESS_TOKEN

echo "------ Beginning 601-sample_app_pol_set.sh ------"

SSR_APP_NAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select(.name=="Demo App - Self-Service Registration") | .name')

SMS_APP_NAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select(.name=="Demo App - Passwordless Login SMS Only") | .name')

PWDLESS_APP_NAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select(.name=="Demo App - Passwordless Login Any Method") | .name')

SAMPLE_APPS[0]="$SSR_APP_NAME"
SAMPLE_APPS[1]="$SMS_APP_NAME"
SAMPLE_APPS[2]="$PWDLESS_APP_NAME"

for SAMPLE_APP in "${SAMPLE_APPS[@]}"; do

    if [ "$SAMPLE_APP" == "Demo App - Self-Service Registration" ]; then

        # get ID of expected matching app name
        SSR_APP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select(.name=="Demo App - Self-Service Registration") | .id')

        #Get SELF REG SFA sign on policy ID
        SELF_POL_SOPA_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications/$SSR_APP_ID/signOnPolicyAssignments" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.signOnPolicyAssignments[].id')

        # delete matching app using ID
        DELETE_SAMPLE_APP_AUTH_POL=$(curl -s --write-out "%{http_code}\n" --location --request DELETE "$API_LOCATION/environments/$ENV_ID/applications/$SSR_APP_ID/signOnPolicyAssignments/$SELF_POL_SOPA_ID" \
        --header 'Content-Type: application/json' --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" --data-raw '')
        # verify app deletion
        DELETE_SAMPLE_APP_AUTH_POL_RESULT=$(echo $DELETE_SAMPLE_APP_AUTH_POL | sed 's@.*}@@')
        if [ "$DELETE_SAMPLE_APP_AUTH_POL_RESULT" == "204" ]; then
            echo "$SAMPLE_APP policy removed successfully..."
        else
            echo "$SAMPLE_APP policy was not removed, or not initally assigned!"
            exit 1
        fi
    fi

    if [ "$SAMPLE_APP" == "Demo App - Passwordless Login SMS Only" ]; then

        # get ID of expected matching app name
        SMS_APP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select(.name=="Demo App - Passwordless Login SMS Only") | .id')

        #Get SMS sign on policy ID
        SMS_POL_SOPA_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications/$SMS_APP_ID/signOnPolicyAssignments" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.signOnPolicyAssignments[].id')

        # delete matching app using ID
         DELETE_SAMPLE_APP_AUTH_POL=$(curl -s --write-out "%{http_code}\n" --location --request DELETE "$API_LOCATION/environments/$ENV_ID/applications/$SMS_APP_ID/signOnPolicyAssignments/$SMS_POL_SOPA_ID" \
        --header 'Content-Type: application/json' --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" --data-raw '')

        # verify app deletion
        DELETE_SAMPLE_APP_AUTH_POL_RESULT=$(echo $DELETE_SAMPLE_APP_AUTH_POL | sed 's@.*}@@')
        if [ "$DELETE_SAMPLE_APP_AUTH_POL_RESULT" == "204" ]; then
            echo "$SAMPLE_APP policy removed successfully..."
        else
            echo "$SAMPLE_APP policy was not removed, or not initally assigned!"
            exit 1
        fi
    fi

    if [ "$SAMPLE_APP" == "Demo App - Passwordless Login Any Method" ]; then

        # get ID of expected matching app name
        PWDLESS_APP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select(.name=="Demo App - Passwordless Login Any Method") | .id')

        #Get passwordless sign on policy ID
        MFA_POL_SOPA_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications/$PWDLESS_APP_ID/signOnPolicyAssignments" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.signOnPolicyAssignments[].id')

        # delete matching app using ID
        DELETE_SAMPLE_APP_AUTH_POL=$(curl -s --write-out "%{http_code}\n" --location --request DELETE "$API_LOCATION/environments/$ENV_ID/applications/$PWDLESS_APP_ID/signOnPolicyAssignments/$MFA_POL_SOPA_ID" \
        --header 'Content-Type: application/json' --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" --data-raw '')

        # verify app deletion
        DELETE_SAMPLE_APP_AUTH_POL_RESULT=$(echo $DELETE_SAMPLE_APP_AUTH_POL | sed 's@.*}@@')
        if [ "$DELETE_SAMPLE_APP_AUTH_POL_RESULT" == "204" ]; then
            echo "$SAMPLE_APP policy removed successfully..."
        else
            echo "$SAMPLE_APP policy was not removed, or not initally assigned!"
            exit 1
        fi
    fi
done

echo "Sample application policy removal checks and tasks completed..."
echo "------ End of 601-sample_app_pol_set.sh ------"
