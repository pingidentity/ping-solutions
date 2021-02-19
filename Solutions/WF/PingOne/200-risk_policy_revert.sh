#!/bin/bash

# revert PingOne Workforce Risk Policy to use Default naming

#Variables needed to be passed for this script:
# API_LOCATION
# ENV_ID
# WORKER_APP_ACCESS_TOKEN

# Get Current Default Risk Policy
RISK_POL_SET_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/riskPolicySets" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.riskPolicySets[]  | select(.name=="High Risk Policy") | .id')

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

if [ "$SET_RISK_POL_NAME_RESULT" == "200" ]; then
  # validate expected risk policy name change
  RISK_POL_STATUS=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/riskPolicySets" \
  --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
  | jq -rc '._embedded.riskPolicySets[]  | select(.name=="Default Risk Policy") | .name')

  # check expected name from config change
  if [ "$RISK_POL_STATUS" = "Default Risk Policy" ]; then
    echo "Verfied Default Risk Policy set back to default from Workforce use case..."
  else
    echo "Default Risk Policy NOT set back to default from Workforce use case successfully!"
    exit 1
  fi
else
    echo "Something went wrong with setting the Workforce Risk Policy back to Default!"
    exit 1
fi