#!/bin/bash

# revert PingOne Workforce Risk Policy to use Default naming

#Variables needed to be passed for this script:
# API_LOCATION
# ENV_ID
# WORKER_APP_ACCESS_TOKEN

#define script for job.
echo "------ Beginning of 200_risk_policy_set.sh ------"

# set global api call retry limit - this can be set to desired amount, default is 2
api_call_retry_limit=2

risk_pol_revert=0

function revert_risk_policy() {
  # Get Current Default Risk Policy
  RISK_POL_SET_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/riskPolicySets" \
  --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.riskPolicySets[]  | select(.name=="Default Workforce High Risk Policy") | .id')

  # Revert Default Risk Policy from Workforce use case
  SET_RISK_POL_NAME=$(curl -s --write-out "%{http_code}\n" --location --request PUT "$API_LOCATION/environments/$ENV_ID/riskPolicySets/$RISK_POL_SET_ID" \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
  --data-raw '{"name" : "Default Risk Policy",
        "default" : true,
        "canUseIntelligenceDataConsent": true,
        "description" : "These are the default values for the risk policy. We recommend changing them according to your organizational needs and adding relevant IP ranges to a whitelist, using the Overrides.",
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

  #put a stop to the madness (potentially) by incrementing the total limit
  risk_pol_revert=$((risk_pol_revert+1))

  #move on to call the check policy
  check_risk_policy
}

function check_risk_policy() {
  if [ "$SET_RISK_POL_NAME_RESULT" == "200" ] && [[ "$risk_pol_set" < "$api_call_retry_limit" ]]; then
    # validate expected risk policy name change
    RISK_POL_STATUS=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/riskPolicySets" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    | jq -rc '._embedded.riskPolicySets[]  | select(.name=="Default Risk Policy") | .name')

    # check expected name from config change
    if [ "$RISK_POL_STATUS" = "Default Risk Policy" ] && [[ "$risk_pol_revert" < "$api_call_retry_limit" ]]; then
      echo "Verfied Default Risk Policy set back to default from Workforce use case..."
    elif [ "$RISK_POL_STATUS" != "Default Risk Policy" ]  && [[ "$risk_pol_set" < "$api_call_retry_limit" ]]; then
      set_risk_policy
    else
      echo "Default Risk Policy NOT set back to default from Workforce use case successfully!"
      exit 1
    fi
  else
      echo "Something went wrong with setting the Workforce Risk Policy back to Default!"
      exit 1
  fi
}

function check_risk_enabled() {
  #check if the environment is allowed to use Risk
  RISK_ENABLED=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/capabilities" \
  --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '.canUseIntelligenceRisk')

  if [[ $RISK_ENABLED == true ]]; then
    #let's do the rest of this
    revert_risk_policy
  elif [[ $ISK_ENABLED == false ]]; then
    echo "PingOne Risk Management is not enabled for this environment"
    exit 0
  fi
}

#check it's enabled (will attempt execute all functions if it is).
check_risk_enabled

#script finish
echo "------ End of 200_risk_policy_set.sh ------"