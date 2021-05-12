#!/bin/bash

#echo Variables to verify
echo "API_LOCATION=$API_LOCATION"
echo "ENV_ID=$ENV_ID"
echo "WORKER_APP_ACCESS_TOKEN=$WORKER_APP_ACCESS_TOKEN"
echo "PINGFED_BASE_URL=$PINGFED_BASE_URL"
echo "PF_USERNAME=$PF_USERNAME"
echo "PF_PASSWORD=$PF_PASSWORD"
echo "AUTH_SERVER_BASE_URL=$AUTH_SERVER_BASE_URL"
echo "PLAYBOOK=pf_post_playbook.yml"

#set variables for future pipeline step.
echo "API_LOCATION=$API_LOCATION" >> ./ciam_docker_vars
echo "ENV_ID=$ENV_ID" >> ./ciam_docker_vars
echo "WORKER_APP_ACCESS_TOKEN=$WORKER_APP_ACCESS_TOKEN" >> ./ciam_docker_vars
echo "PINGFED_BASE_URL=$PINGFED_BASE_URL" >> ./ciam_docker_vars
echo "PF_USERNAME=$PF_USERNAME" >> ./ciam_docker_vars
echo "PF_PASSWORD=$PF_PASSWORD" >> ./ciam_docker_vars
echo "AUTH_SERVER_BASE_URL=$AUTH_SERVER_BASE_URL" >> ./ciam_docker_vars
echo "PLAYBOOK=pf_post_playbook.yml" >> ./ciam_docker_vars