#!/bin/bash

# configure PingOne Sample SAML Apps for CIAM authentication policies

#Variables needed to be passed for this script:
# API_LOCATION
# ENV_ID
# WORKER_APP_ACCESS_TOKEN

#Get the new SELF REG SFA ID
SELF_POL_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
| jq -rc '._embedded.signOnPolicies[] | select(.name=="Demo_Self-Registration_Login_Policy") | .id')

#Get the SELF RED SFA App ID
SSR_APP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select(.name=="Demo App - Self-Service Registration") | .id')

#Assign SELF RED SFA App to SELF REG SFA policy
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
    echo "SELF RED SFA App to SELF REG SFA assigned successfully..."
else
    echo "SELF RED SFA App to SELF REG SFA NOT assigned successfully!"
    exit 1
fi

#Get the new SMS ID
SMS_POL_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
| jq -rc '._embedded.signOnPolicies[] | select(.name=="Demo_Passwordless_SMS_Login_Policy") | .id')

SMS_APP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select(.name=="Demo App - Passwordless Login SMS Only") | .id')

#Assign SMS App to SMS Policy
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
    echo "SMS App to SMS Policy assigned successfully..."
else
    echo "SMS App to SMS Policy NOT assigned successfully!"
    exit 1
fi


#Get the new passwordless ID
ALL_MFA_POL_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
| jq -rc '._embedded.signOnPolicies[] | select(.name=="Demo_Passwordless_Any_Method_Login_Policy") | .id')

PWDLESS_APP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select(.name=="Demo App - Passwordless Login Any Method") | .id')

#Assign PWDLESS App to All MFA Policy
ASSIGN_PWDLESS_APP_POL=$(curl -s --write-out "%{http_code}\n" --location --request POST "$API_LOCATION/environments/$ENV_ID/applications/$PWDLESS_APP_ID/signOnPolicyAssignments" \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '{
    "priority": 1,
    "signOnPolicy": {
    	"id": "'"$ALL_MFA_POL_ID"'"
    }
}')

# verify app auth policy assigned
ASSIGN_PWDLESS_APP_POL_RESULT=$(echo $ASSIGN_PWDLESS_APP_POL | sed 's@.*}@@')
if [ "$ASSIGN_PWDLESS_APP_POL_RESULT" == "201" ]; then
    echo "PWDLESS App to All MFA Policy assigned successfully..."
else
    echo "PWDLESS App to All MFA Policy NOT assigned successfully!"
    exit 1
fi