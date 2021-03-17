#!/bin/bash

#update PingOne policy to use passphrase policy using default values for the config.

#Variables needed to be passed for this script:
# API_LOCATION
# ENV_ID
# WORKER_APP_ACCESS_TOKEN

#define script for job.
echo "------ Beginning of 100-pass_policy_set.sh ------"

# set global api call retry limit - this can be set to desired amount, default is 2
api_call_retry_limit=2

pass_pol_set=0

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
      echo "Passphrase policy set successfully"
    else
      echo "Passphrase policy not set successfully"
      exit 1
    fi
  fi
}

#execute the function 
set_password_policy

echo "------ End of 100-pass_policy_set.sh ------"