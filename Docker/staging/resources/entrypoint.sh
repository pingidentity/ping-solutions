#!/bin/sh

#download our repo into the container
#wget https://github.com/pingidentity/ping-solutions/archive/refs/heads/ansible.zip -O /ansible/playbooks/ansible.zip
git clone --depth 1 -b0.1-ansible https://github.com/pingidentity/ping-solutions.git /ansible/playbooks/

#extract zip
#unzip /ansible/playbooks/ansible.zip -d /ansible/playbooks/

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
/ansible/playbooks/ansible/$PLAYBOOK
