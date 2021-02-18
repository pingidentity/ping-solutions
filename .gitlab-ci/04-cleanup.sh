#!/bin/bash
# Script to test PingOne instance against trial specifications

#setup the env name
export ENV_NAME=$( date +"RUNNER_ENV_"%Y%m%d )
#set Ping One variables for WF variable sub
export CLIENT_ID=$(cat ./.gitlab-ci/cypress.d/WF_client_id.txt)
export CLIENT_SECRET=$(cat ./.gitlab-ci/cypress.d/WF_client_secret.txt)
export ENV_ID=$(cat ./.gitlab-ci/cypress.d/WF_envid.txt)

echo "Performing pipeline env cleanup."
echo "Note: If pipeline does not succeed this may error if things are not already configured, we want to run it regardless just in case."

echo "Running variable substitution..."
cat ./.gitlab-ci/cypress.d/cypress/base_files/delete_env.base | \
sed -e "s/ENV_ID/$ADMIN_ENV_ID/g" -e "s/TEST_USERNAME/$CONSOLE_USERNAME/g" -e "s/TEST_PASSWORD/$CONSOLE_PASSWORD/g" -e "s/ENV_NM/WF_$ENV_NAME/g" -e "s/PROD_NM/WF/g" > \
.gitlab-ci/cypress.d/cypress/integration/tests/01-delete_WF_env.js 

#set Ping One variables for CIAM variable sub
export CLIENT_ID=$(cat ./.gitlab-ci/cypress.d/CIAM_client_id.txt)
export CLIENT_SECRET=$(cat ./.gitlab-ci/cypress.d/CIAM_client_secret.txt)
export ENV_ID=$(cat ./.gitlab-ci/cypress.d/CIAM_envid.txt)

echo "Running variable substitution..."
cat ./.gitlab-ci/cypress.d/cypress/base_files/delete_env.base | \
sed -e "s/ENV_ID/$ADMIN_ENV_ID/g" -e "s/TEST_USERNAME/$CONSOLE_USERNAME/g" -e "s/TEST_PASSWORD/$CONSOLE_PASSWORD/g" -e "s/ENV_NM/CIAM_$ENV_NAME/g" -e "s/PROD_NM/CIAM/g" > \
.gitlab-ci/cypress.d/cypress/integration/tests/02-delete_CIAM_env.js 

DOCKER_RUN_OPTIONS="-i --rm"
# Only allocate tty if we detect one
if [ -t 0 ] && [ -t 1 ]; then
    DOCKER_RUN_OPTIONS="$DOCKER_RUN_OPTIONS -t"
fi

echo "Performing environment revert via Docker..."
docker run $DOCKER_RUN_OPTIONS --ipc=host -v $PWD/.gitlab-ci/cypress.d:/e2e -w /e2e -entrypoint=cypress cypress/included:6.3.0 --browser chrome run
#docker run $DOCKER_RUN_OPTIONS --ipc=host -v $PWD/.gitlab-ci/cypress.d:/e2e -w /e2e -entrypoint=cypress cypress/included:6.3.0 --browser chrome run --record --key $CYPRESS_RECORD_KEY

rm ./.gitlab-ci/cypress.d/cypress/integration/tests/*.js 
rm ./.gitlab-ci/cypress.d/cypress.json
rm ./.gitlab-ci/cypress.d/*.txt