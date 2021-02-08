#!/bin/bash

#update PingOne policy to use passphrase policy using default values for the config.

#Variables needed to be passed for this script:
# API_LOCATION
# ENV_ID
# WORKER_APP_ACCESS_TOKEN

#get id for the Pasphrase policy
PASS_POL_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/passwordPolicies" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN " \
| jq -rc '._embedded.passwordPolicies[] | select(.name=="Basic") | .id')

#set default active password policy to Basic
curl --location --request PUT "$API_LOCATION/environments/$ENV_ID/passwordPolicies/$PASS_POL_ID" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN " \
--header 'Content-Type: application/json' \
--data-raw '{
"id" : "4e58ed0c-ab50-4515-82d8-79c4d6fe8069",
      "environment" : {
        "id" : "d610dc18-600b-46bd-a4cb-27a6c5d37b85"
      },
      "name" : "Basic",
      "description" : "A relaxed standard policy to allow for maximum customer flexibility.",
      "excludesProfileData" : false,
      "notSimilarToCurrent" : false,
      "excludesCommonlyUsed" : true,
      "lockout" : {
        "failureCount" : 5,
        "durationSeconds" : 900
      },
      "length" : {
        "min" : 8,
        "max" : 255
      },
      "minCharacters" : {
        "~!@#$%^&*()-_=+[]{}|;:,.<>/?" : 1,
        "0123456789" : 1,
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ" : 1,
        "abcdefghijklmnopqrstuvwxyz" : 1
      },
      "default" : true
}'