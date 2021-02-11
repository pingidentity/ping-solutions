#!/bin/bash
# Script to test PingOne instance against trial specifications

#setup the env name
export ENV_NAME=$( date +"RUNNER_ENV_"%Y%m%d )
#set Ping One variables for WF
export CLIENT_ID=$(cat ./.gitlab-ci/cypress.d/client_id.txt)
export CLIENT_SECRET=$(cat ./.gitlab-ci/cypress.d/client_secret.txt)
export ENV_ID=$(cat ./.gitlab-ci/cypress.d/envid.txt)

echo "Performing Workforce env cleanup."

echo "Running variable substitution..."
cat ./.gitlab-ci/cypress.d/cypress/base_files/reverted_state_check.base | \
awk -v env="$ADMIN_ENV_ID" -v cu="$CONSOLE_USERNAME" -v cp="$CONSOLE_PASSWORD"  -v ename="$ENV_NAME" \
-v eid="ENV_ID" -v tu="TEST_USERNAME" -v tp="TEST_PASSWORD" -v oename="ENV_NM" \
'{sub(eid,env)} {sub(tu,cu)} {sub(oename,ename)} {sub(tp,cp)}1' >\
./.gitlab-ci/cypress.d/cypress/integration/tests/reverted_state_check.js 

DOCKER_RUN_OPTIONS="-i --rm"
# Only allocate tty if we detect one
if [ -t 0 ] && [ -t 1 ]; then
    DOCKER_RUN_OPTIONS="$DOCKER_RUN_OPTIONS -t"
fi

echo "Performing environment revert via Docker..."
docker run $DOCKER_RUN_OPTIONS --ipc=host -v $PWD/.gitlab-ci/cypress.d:/e2e -w /e2e -entrypoint=cypress cypress/included:6.3.0 --browser chrome run --record --key $CYPRESS_RECORD_KEY

rm ./.gitlab-ci/cypress.d/cypress/integration/tests/reverted_state_check.js 
rm ./.gitlab-ci/cypress.d/cypress.json
rm ./.gitlab-ci/cypress.d/*.txt