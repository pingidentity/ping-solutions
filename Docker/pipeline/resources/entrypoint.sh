#!/bin/sh

#download our repo into the container
#wget https://github.com/pingidentity/ping-solutions/archive/refs/heads/ansible.zip -O /ansible/playbooks/ansible.zip
echo "Pipeline branch used is $PIPELINE_BRANCH"
git clone --depth 1 -b$PIPELINE_BRANCH https://github.com/pingidentity/ping-solutions.git /ansible/playbooks/

#extract zip
#unzip /ansible/playbooks/ansible.zip -d /ansible/playbooks/


#echo for pipeline
echo '{' > ./vars.txt
if [[ -n "$API_LOCATION" ]]; then
    echo "\"API_LOCATION\":\"$API_LOCATION\"," >> ./vars.txt
fi
if [[ -n "$ADMIN_ENV_ID" ]]; then
    echo "\"ADMIN_ENV_ID\":\"$ADMIN_ENV_ID\"," >> ./vars.txt
fi
if [[ -n "$ENV_ID" ]]; then
    echo "\"ENV_ID\":\"$ENV_ID\"," >> ./vars.txt
fi
if [[ -n "$CIAM_ENV_ID" ]]; then
    echo "\"CIAM_ENV_ID\":\"$CIAM_ENV_ID\"," >> ./vars.txt
fi
if [[ -n "$WF_ENV_ID" ]]; then
    echo "\"WF_ENV_ID\":\"$WF_ENV_ID\"," >> ./vars.txt
fi
if [[ -n "$WORKER_APP_ACCESS_TOKEN" ]]; then
    echo "\"WORKER_APP_ACCESS_TOKEN\":\"$WORKER_APP_ACCESS_TOKEN\"," >> ./vars.txt
fi
if [[ -n "$PINGFED_BASE_URL" ]]; then
    echo "\"PINGFED_BASE_URL\":\"$PINGFED_BASE_URL\","  >> ./vars.txt
fi
if [[ -n "$PF_USERNAME" ]]; then
    echo "\"PF_USERNAME\":\"$PF_USERNAME\"," >> ./vars.txt
fi
if [[ -n "$PF_PASSWORD" ]]; then
    echo "\"PF_PASSWORD\":\"$PF_PASSWORD\"," >> ./vars.txt
fi
if [[ -n "$AUTH_SERVER_BASE_URL" ]]; then
    echo "\"AUTH_SERVER_BASE_URL\":\"$AUTH_SERVER_BASE_URL\"," >> ./vars.txt
fi
if [[ -n "$ADMIN_CLIENT_ID" ]]; then
    echo "\"ADMIN_CLIENT_ID\":\"$ADMIN_CLIENT_ID\"," >> ./vars.txt
fi
if [[ -n "$ADMIN_CLIENT_SECRET" ]]; then
    echo "\"ADMIN_CLIENT_SECRET\":\"$ADMIN_CLIENT_SECRET\"," >> ./vars.txt
fi
if [[ -n "$API_CLIENT_ID" ]]; then
    echo "\"API_CLIENT_ID\":\"$API_CLIENT_ID\"," >> ./vars.txt
fi
if [[ -n "$API_CLIENT_SECRET" ]]; then
    echo "\"API_CLIENT_SECRET\":\"$API_CLIENT_SECRET\"," >> ./vars.txt
fi
if [[ -n "$CONSOLE_USERNAME" ]]; then
    echo "\"CONSOLE_USERNAME\":\"$CONSOLE_USERNAME\"," >> ./vars.txt
fi
if [[ -n "$CONSOLE_PASSWORD" ]]; then
    echo "\"CONSOLE_PASSWORD\":\"$CONSOLE_PASSWORD\"," >> ./vars.txt
fi
if [[ -n "$CYPRESS_PROJECT_ID" ]]; then
    echo "\"CYPRESS_PROJECT_ID\":\"$CYPRESS_PROJECT_ID\"," >> ./vars.txt
fi
if [[ -n "$PIPELINE_APP_ACCESS_TOKEN" ]]; then
    echo "\"PIPELINE_APP_ACCESS_TOKEN\":\"$PIPELINE_APP_ACCESS_TOKEN\"," >> ./vars.txt
fi
#RingCentral
if [[ -n "$RINGCENTRAL_CLIENT_ID" ]]; then
    echo "\"RINGCENTRAL_CLIENT_ID\":\"$RINGCENTRAL_CLIENT_ID\"," >> ./vars.txt
fi
if [[ -n "$RINGCENTRAL_CLIENT_SECRET" ]]; then
    echo "\"RINGCENTRAL_CLIENT_SECRET\":\"$RINGCENTRAL_CLIENT_SECRET\"," >> ./vars.txt
fi
if [[ -n "$RINGCENTRAL_USERNAME" ]]; then
    echo "\"RINGCENTRAL_USERNAME\":\"$RINGCENTRAL_USERNAME\"," >> ./vars.txt
fi
if [[ -n "$RINGCENTRAL_PASSWORD" ]]; then
    echo "\"RINGCENTRAL_PASSWORD\":\"$RINGCENTRAL_PASSWORD\"," >> ./vars.txt
fi
if [[ -n "$RUNNER_USER_TEST_PASSWORD" ]]; then
    echo "\"RUNNER_USER_TEST_PASSWORD\":\"$RUNNER_USER_TEST_PASSWORD\"," >> ./vars.txt
fi
echo '"fake":"fake"' >> ./vars.txt
echo '}' >> ./vars.txt

echo "Variable values:"
cat ./vars.txt
#run the playbook
ansible-playbook --extra-vars @vars.txt /ansible/playbooks/.gitlab-ci/$PLAYBOOK -vvv
