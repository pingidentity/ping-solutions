#!/bin/bash

#set the dir location
script_dir="$(cd "$(dirname "$0")"; pwd)"
#set the cypress directory
cypress_dir=$(echo "$script_dir/../cypress")

export CLIENT_ID=$(cat "$cypress_dir"/WF_client_id.txt)
export CLIENT_SECRET=$(cat "$cypress_dir"/WF_client_secret.txt)
export ENV_ID=$(cat "$cypress_dir"/WF_envid.txt)

#get a worker app token to run our tests (WF)
export WORKER_APP_ACCESS_TOKEN=$(curl -u $CLIENT_ID:$CLIENT_SECRET \
--location --request POST "https://auth.pingone.com/$ENV_ID/as/token" \
--header "Content-Type: application/x-www-form-urlencoded" \
--data-raw 'grant_type=client_credentials' \
| jq -r '.access_token')

#finessse the BoM
PFeddy_add=$(curl --location --request PUT "$API_LOCATION/environments/$ENV_ID/billOfMaterials" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--header 'Content-Type: application/json' \
--data-raw '{
  "products": [
    {
      "type": "PING_FEDERATE"
    },
    {
        "type": "PING_ONE_BASE"
    },
    {
        "type": "PING_ID"
    },
    {
        "type": "PING_ONE_RISK"
    }
  ]
}')

#echo Variables to verify
echo "API_LOCATION=$API_LOCATION"
echo "ENV_ID=$ENV_ID"
echo "WORKER_APP_ACCESS_TOKEN=$WORKER_APP_ACCESS_TOKEN"
echo "PINGFED_BASE_URL=$PINGFED_BASE_URL"
echo "PF_USERNAME=$PF_USERNAME"
echo "PF_PASSWORD=$PF_PASSWORD"
echo "AUTH_SERVER_BASE_URL=$AUTH_SERVER_BASE_URL"
echo "PLAYBOOK=pf_post_playbook.yml"

echo "API_LOCATION=$API_LOCATION" >> ./wf_docker_vars
echo "ENV_ID=$ENV_ID" >> ./wf_docker_vars
echo "WORKER_APP_ACCESS_TOKEN=$WORKER_APP_ACCESS_TOKEN" >> ./wf_docker_vars
echo "PINGFED_BASE_URL=$PINGFED_BASE_URL" >> ./wf_docker_vars
echo "PF_USERNAME=$PF_USERNAME" >> ./wf_docker_vars
echo "PF_PASSWORD=$PF_PASSWORD" >> ./wf_docker_vars
echo "AUTH_SERVER_BASE_URL=$AUTH_SERVER_BASE_URL" >> ./wf_docker_vars
echo "PLAYBOOK=p1_pf_playbook.yml" >> ./wf_docker_vars