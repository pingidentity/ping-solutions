#!/bin/bash

# creates sample user populations in PingOne

#Variables needed to be passed for this script:
# API_LOCATION
# ENV_ID
# WORKER_APP_ACCESS_TOKEN


# Get Current MFA Authentication Policy
MFA_POL_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies/" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
| jq -rc '._embedded.signOnPolicies[] | select(.name=="Multi_Factor") | .id')

MFA_POL_ID1=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies/$MFA_POL_ID/actions" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" )

#################################
#create the new Multi-factor trial policy
MFA_POL_CREATE=$(curl --location --request POST "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '{
  "name": "Trial_Multi_Factor",
  "default": "false",
  "description": "A sign-on policy that requires primary username and password along with pre-configured additions for trial purposes"
}')


#Get the new ID
MFA_POL_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
| jq -rc '._embedded.signOnPolicies[] | select(.name=="Trial_Multi_Factor") | .id')

MFA_ACTION_CREATE=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/signOnPolicies/$MFA_POL_ID/actions" \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '{
  "priority": 30,
  "type": "LOGIN",
  "condition": {
    "secondsSince": "${session.lastSignOn.withAuthenticator.pwd.at}",
    "greater": 28800
    },
  "recovery": {
    "enabled": true
  },
  "registration": {
    "enabled": false
  }
}')


MFA_ACTION_CREATE=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/signOnPolicies/$MFA_POL_ID/actions" \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '{
  "priority": 30,
  "type": "MULTI_FACTOR_AUTHENTICATION",
  "condition": {
    "or": [
      {
        "secondsSince": "${session.lastSignOn.withAuthenticator.mfa.at}",
        "greater": 3600
      },
      {
        "ipRisk": {
          "minScore": 80,
          "maxScore": 100
        },
        "valid": "${flow.request.http.remoteIp}"
      }
    ]
    },
  "priority": 2,
  "sms": {
    "enabled": true
  },
  "authenticator": {
    "enabled": false
  },
  "email": {
    "enabled": true
  },
   "boundBiometrics": {
    "enabled": true
  },
  "securityKey": {
    "enabled": true
  },
 "applications": []
}')

MFA_POL_DEFAULT=$(curl -s --location --request PUT "$API_LOCATION/environments/$ENV_ID/signOnPolicies/$MFA_POL_ID" \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '{
  "name": "Trial_Multi_Factor",
  "default": "true",
  "description": "A sign-on policy that requires primary username and password along with pre-configured additions for trial purposes"
}')

#make sure Single is default agin
MFA_POL_DEF=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies/" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
| jq -r '._embedded.signOnPolicies[] | select(.name=="Trial_Multi_Factor") | .default')

if [ "$MFA_POL_DEF" == "true" ]; then
    echo "Trial Multi Factor Auth has been set to default..."
  else
    echo "Trial Multi Factor Auth not set successfully!"
    exit 1
  fi