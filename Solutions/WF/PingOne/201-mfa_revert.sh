#!/bin/bash

# creates sample user populations in PingOne

#Variables needed to be passed for this script:
# API_LOCATION
# ENV_ID
# WORKER_APP_ACCESS_TOKEN

# Get Default Standard Authentication Policy to set back to default
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

# Get the trial policy
MFA_POL_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
| jq -rc '._embedded.signOnPolicies[] | select(.name=="Trial_Multi_Factor") | .id')

MFA_POL_DEL=$(curl -s --location --request DELETE "$API_LOCATION/environments/$ENV_ID/signOnPolicies/$MFA_POL_ID" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '')

#make sure Single is default agin
SFA_POL_DEF=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies/" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
| jq -r '._embedded.signOnPolicies[] | select(.name=="Single_Factor") | .default')

if [ "$SFA_POL_DEF" == "true" ]; then
    echo "Default Single Factor Auth has been set to default..."
  else
    echo "Single Factor Auth not set successfully!"
    exit 1
  fi