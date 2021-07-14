#!/bin/sh

#run the playbook
ansible-playbook \
--extra-vars \
"API_LOCATION=$API_LOCATION \
ENV_ID=$ENV_ID \
WORKER_APP_ACCESS_TOKEN=$WORKER_APP_ACCESS_TOKEN \
PINGFED_BASE_URL=$PINGFED_BASE_URL \
PF_USERNAME=$PF_USERNAME \
PF_PASSWORD=$PF_PASSWORD \
AUTH_SERVER_BASE_URL=$AUTH_SERVER_BASE_URL" \
/builds/solutions/thunder/ansible/p1_pf_playbook.yml -vvv
