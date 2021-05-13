#!/bin/bash

set -eo pipefail

export ENV_ID=$(cat "$cypress_dir"/WF_envid.txt)

#echo Variables to verify
echo "API_LOCATION=$API_LOCATION"
echo "ENV_ID=$ENV_ID"
echo "WORKER_APP_ACCESS_TOKEN=$WORKER_APP_ACCESS_TOKEN"
echo "PINGFED_BASE_URL=$WF_PINGFED_BASE_URL"
echo "PF_USERNAME=$PF_USERNAME"
echo "PF_PASSWORD=$PF_PASSWORD"
echo "AUTH_SERVER_BASE_URL=$AUTH_SERVER_BASE_URL"
echo "PLAYBOOK=pf_post_playbook.yml -vvv"

#set variables for future pipeline step.
echo "API_LOCATION=$API_LOCATION" >> ./wf_docker_vars
echo "ENV_ID=$ENV_ID" >> ./wf_docker_vars
echo "WORKER_APP_ACCESS_TOKEN=$WORKER_APP_ACCESS_TOKEN" >> ./wf_docker_vars
echo "PINGFED_BASE_URL=$WF_PINGFED_BASE_URL" >> ./wf_docker_vars
echo "PF_USERNAME=$PF_USERNAME" >> ./wf_docker_vars
echo "PF_PASSWORD=$PF_PASSWORD" >> ./wf_docker_vars
echo "AUTH_SERVER_BASE_URL=$AUTH_SERVER_BASE_URL" >> ./wf_docker_vars
echo "PLAYBOOK=pf_post_playbook.yml -vvv" >> ./wf_docker_vars
