#!/bin/bash
# Script to test PingOne instance against trial specifications

#setup the env name
export ENV_NAME=$( date +"RUNNER_ENV_"%Y%m%d )

#set Ping One variables for WF
export CLIENT_ID=$(cat ./.gitlab-ci/cypress.d/WF_client_id.txt)
export CLIENT_SECRET=$(cat ./.gitlab-ci/cypress.d/WF_client_secret.txt)
export ENV_ID=$(cat ./.gitlab-ci/cypress.d/WF_envid.txt)

echo "Performing tests on reverted state."
echo "Running variable substitution..."
cat ./.gitlab-ci/cypress.d/cypress/base_files/reverted_state_check.base | \
sed -e "s/ENV_ID/$ADMIN_ENV_ID/g" -e "s/TEST_USERNAME/$CONSOLE_USERNAME/g" -e "s/TEST_PASSWORD/$CONSOLE_PASSWORD/g" -e "s/ENV_NM/$ENV_NAME/g" > \
.gitlab-ci/cypress.d/cypress/integration/tests/01-WF_reverted_state_check.js 


#set Ping One variables for CIAM
export CLIENT_ID=$(cat ./.gitlab-ci/cypress.d/CIAM_client_id.txt)
export CLIENT_SECRET=$(cat ./.gitlab-ci/cypress.d/CIAM_client_secret.txt)
export ENV_ID=$(cat ./.gitlab-ci/cypress.d/CIAM_envid.txt)

#echo "Performing tests on configured state."
#echo "Performing CIAM variable substitution..."
#cat ./.gitlab-ci/cypress.d/cypress/base_files/reverted_state_check.base | \
#sed -e "s/ENV_ID/$ADMIN_ENV_ID/g" -e "s/TEST_USERNAME/$CONSOLE_USERNAME/g" -e "s/TEST_PASSWORD/$CONSOLE_PASSWORD/g" -e "s/ENV_NM/$ENV_NAME/g" > \
#.gitlab-ci/cypress.d/cypress/integration/tests/02-WF_reverted_state_check.js 


DOCKER_RUN_OPTIONS="-i --rm"
# Only allocate tty if we detect one
if [ -t 0 ] && [ -t 1 ]; then
    DOCKER_RUN_OPTIONS="$DOCKER_RUN_OPTIONS -t"
fi

echo "Performing validation on reverted state."
docker run $DOCKER_RUN_OPTIONS --ipc=host -v $PWD/.gitlab-ci/cypress.d:/e2e -w /e2e -entrypoint=cypress cypress/included:6.3.0 --browser chrome run --record --key $CYPRESS_RECORD_KEY

rm ./.gitlab-ci/cypress.d/cypress/integration/tests/*.js