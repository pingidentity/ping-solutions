#!/bin/bash

#update PingOne policy to use passphrase policy using default values for the config.

#Variables needed to be passed for this script:
# API_LOCATION
# ENV_ID
# WORKER_APP_ACCESS_TOKEN

#get id for the Pasphrase policy
PASS_POL_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/passwordPolicies" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
| jq -rc '._embedded.passwordPolicies[] | select(.name=="Passphrase") | .id')

#set default active password policy to Passphrase
curl --location --request PUT "$API_LOCATION/environments/$ENV_ID/passwordPolicies/$PASS_POL_ID" \
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
      "minComplexity" : 7,
      "maxAgeDays" : 182,
      "minAgeDays" : 1,
      "history" : {
        "count" : 6,
        "retentionDays" : 365
      },
      "lockout" : {
        "failureCount" : 5,
        "durationSeconds" : 900
      },
      "default" : true
    }'