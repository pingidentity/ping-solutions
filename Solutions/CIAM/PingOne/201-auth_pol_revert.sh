#!/bin/bash

# creates sample user populations in PingOne

#Variables needed to be passed for this script:
# API_LOCATION
# ENV_ID
# WORKER_APP_ACCESS_TOKEN

# Get Default Standard Authentication Policy to set back to default
echo "Setting Single_Factor policy back to standard."
SFA_POL_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies/" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
| jq -r '._embedded.signOnPolicies[] | select(.name=="Single_Factor") | .id')

#set Single Factor to default
SFA_POL_DEFAULT=$(curl -s --location --request PUT "$API_LOCATION/environments/$ENV_ID/signOnPolicies/$SFA_POL_ID" \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '{
  "name": "Single_Factor",
  "default": "true",
  "description": "A sign-on policy that requires username and password"
}')

# Get the Demo policy IDs
#Get the SELF REG SFA ID
echo "Getting policy IDs for deletion."
SELF_POL_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
| jq -rc '._embedded.signOnPolicies[] | select(.name=="Demo_Self-Registration_Login_Policy") | .id')
#Get the SMS ID
SMS_POL_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
| jq -rc '._embedded.signOnPolicies[] | select(.name=="Demo_Passwordless_SMS_Login_Policy") | .id')
#Get the passwordless ID
ALL_MFA_POL_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
| jq -rc '._embedded.signOnPolicies[] | select(.name=="Demo_Passwordless_Any_Method_Login_Policy") | .id')
#Get the MFA ID
MFA_POL_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
| jq -rc '._embedded.signOnPolicies[] | select(.name=="Demo_Multi_Factor") | .id')

#Delete the policies
echo "Deleting Demo Policies"
SELF_POL_DEL=$(curl -s --location --request DELETE "$API_LOCATION/environments/$ENV_ID/signOnPolicies/$SELF_POL_ID" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '')
SMS_POL_DEL=$(curl -s --location --request DELETE "$API_LOCATION/environments/$ENV_ID/signOnPolicies/$SMS_POL_ID" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '')
ALL_MFA_POL_DEL=$(curl -s --location --request DELETE "$API_LOCATION/environments/$ENV_ID/signOnPolicies/$ALL_MFA_POL_ID" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '')
MFA_POL_DEL=$(curl -s --location --request DELETE "$API_LOCATION/environments/$ENV_ID/signOnPolicies/$MFA_POL_ID" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '')