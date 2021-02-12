#!/bin/bash
# Script to configure PingOne instance to trial specifications

echo "checking base configuration"
pwd
env
echo "$USER"
type jq
type docker
docker info
docker version
type docker-compose
docker-compose version
type envsubst
envsubst --version
type git
git --version
type sed

[ ! -d "$HOME"/.pingidentity ] && mkdir "$HOME"/.pingidentity
[ ! -f "$HOME"/.pingidentity/devops ] && \
  cat <<DEVOPS > "$HOME"/.pingidentity/devops
PING_IDENTITY_ACCEPT_EULA=${PING_IDENTITY_ACCEPT_EULA:-YES}
PING_IDENTITY_DEVOPS_USER=$PING_IDENTITY_DEVOPS_USER
PING_IDENTITY_DEVOPS_KEY=$PING_IDENTITY_DEVOPS_KEY
PING_IDENTITY_DEVOPS_HOME=${PING_IDENTITY_DEVOPS_HOME:-$HOME/projects/devops}
PING_IDENTITY_DEVOPS_REGISTRY=${PING_IDENTITY_DEVOPS_REGISTRY:-docker.io/pingidentity}
PING_IDENTITY_DEVOPS_TAG=${PING_IDENTITY_DEVOPS_TAG:-latest}
DEVOPS

#WORKFORCEEEEEEEEEEE

#setup the env name. echoing because something might not be set?
export ENV_NAME=$( date +"RUNNER_ENV_"%Y%m%d )
if [ -z ${ENV_NAME+x} ]; then echo "Console password is unset" && exit 1; else echo "Environment name is $ENV_NAME"; fi
if [ -z ${ADMIN_ENV_ID+x} ]; then echo "Console password is unset" && exit 1; else echo "Admin Environment ID is $ADMIN_ENV_ID"; fi
if [ -z ${CONSOLE_USERNAME+x} ]; then echo "Console password is unset" && exit 1; else echo "Console user is $CONSOLE_USERNAME"; fi
if [ -z ${CONSOLE_PASSWORD+x} ]; then echo "Console password is unset" && exit 1; else echo "Console password is set."; fi

echo "Cypress project ID is $CYPRESS_PROJECT_ID. Cypress key is $CYPRESS_RECORD_KEY"



echo "Performing variable substitution"
#let's set this bad boy up!
#note: the ENV_ID up here is the master/admin ENV_ID for an environment, not the new. I'm going to forget about this.
echo "Attempt will be made to remove env if exists, just in case a previous run/manual testing occured"
cat ./.gitlab-ci/cypress.d/cypress/base_files/delete_env.base | \
sed -e "s/ENV_ID/$ADMIN_ENV_ID/g" -e "s/TEST_USERNAME/$CONSOLE_USERNAME/g" -e "s/TEST_PASSWORD/$CONSOLE_PASSWORD/g" -e "s/ENV_NM/$ENV_NAME/g" > \
.gitlab-ci/cypress.d/cypress/integration/tests/01-delete_env.js 

echo "Setting up P14C environment"
cat ./.gitlab-ci/cypress.d/cypress/base_files/create_env.base | \
sed -e "s/ENV_ID/$ADMIN_ENV_ID/g" -e "s/TEST_USERNAME/$CONSOLE_USERNAME/g" -e "s/TEST_PASSWORD/$CONSOLE_PASSWORD/g" -e "s/ENV_NM/$ENV_NAME/g" > \
.gitlab-ci/cypress.d/cypress/integration/tests/02-create_env.js 

cat ./.gitlab-ci/cypress.d/cypress/base_files/create_worker_app.base | \
sed -e "s/ENV_ID/$ADMIN_ENV_ID/g" -e "s/TEST_USERNAME/$CONSOLE_USERNAME/g" -e "s/TEST_PASSWORD/$CONSOLE_PASSWORD/g" -e "s/ENV_NM/$ENV_NAME/g" > \
.gitlab-ci/cypress.d/cypress/integration/tests/03-create_worker_app.js 

cat ./.gitlab-ci/cypress.d/cypress/base_files/cypress.json.base | sed -e "s/PID/$CYPRESS_PROJECT_ID/g" > .gitlab-ci/cypress.d/cypress.json


#lets crash and burn here if these don't exist
if [ ! -f ./.gitlab-ci/cypress.d/cypress/integration/tests/02-create_env.js ] || \
[ ! -f ./.gitlab-ci/cypress.d/cypress/integration/tests/03-create_worker_app.js ]; then
  echo "Variable substitution to set up environment not performed properly, exiting now..."
  exit 1
fi

#docker base options
DOCKER_RUN_OPTIONS="-i --rm"
# Only allocate tty if we detect one
if [ -t 0 ] && [ -t 1 ]; then
    DOCKER_RUN_OPTIONS="$DOCKER_RUN_OPTIONS -t"
fi

echo "Launching Docker to set up environment"

docker run $DOCKER_RUN_OPTIONS --ipc=host -v $PWD/.gitlab-ci/cypress.d:/e2e -w /e2e -entrypoint=cypress cypress/included:6.3.0 --browser chrome run 
#docker run $DOCKER_RUN_OPTIONS --ipc=host -v $PWD/.gitlab-ci/cypress.d:/e2e -w /e2e -entrypoint=cypress cypress/included:6.3.0 --browser chrome run --record --key $CYPRESS_RECORD_KEY


rm .gitlab-ci/cypress.d/cypress/integration/tests/*.js 

#set Ping One variables for WF
export CLIENT_ID=$(cat ./.gitlab-ci/cypress.d/client_id.txt)
export CLIENT_SECRET=$(cat ./.gitlab-ci/cypress.d/client_secret.txt)
export ENV_ID=$(cat ./.gitlab-ci/cypress.d/envid.txt)


#get a worker app token to run our tests (WF)
export WORKER_APP_ACCESS_TOKEN=$(curl -u $CLIENT_ID:$CLIENT_SECRET \
--location --request POST "https://auth.pingone.com/$ENV_ID/as/token" \
--header "Content-Type: application/x-www-form-urlencoded" \
--data-raw 'grant_type=client_credentials' \
| jq -r '.access_token')

echo "Performing base PingOne WF configuration"
echo "Environment ID is $ENV_ID"
echo "API URL path is $API_LOCATION"
echo "Current Org ID is $ORG_ID"
echo "WF worker token is $WORKER_APP_ACCESS_TOKEN"

#performing initial PingOne WF creation scripts
echo "Running WF creation scripts ....       ..   .. .  ."
for script in ./Solutions/WF/PingOne/*create.sh; do
  echo "Executing $script..."
  bash $script 
done

#performing initial PingOne WF set scripts
echo "Running WF set scripts . . . .   .   . _ . .   . _ _ .   _ _   ."
for script in ./Solutions/WF/PingOne/*set.sh; do
  echo "Executing $script..."
  bash $script 
done

#CCCCCCCCIIIIIIIIIAAAAAAAAAMMMMMMMMM

#set Ping One variables for CIAM
export CLIENT_ID=$CIAM_CLIENT_ID
export CLIENT_SECRET=$CIAM_CLIENT_SECRET
export ENV_ID=$CIAM_ENV_ID

#get a worker app token to run our tests (CIAM)
export WORKER_APP_ACCESS_TOKEN=$(curl -u $CLIENT_ID:$CLIENT_SECRET \
--location --request POST "https://auth.pingone.com/$ENV_ID/as/token" \
--header "Content-Type: application/x-www-form-urlencoded" \
--data-raw 'grant_type=client_credentials' \
| jq -r '.access_token')

echo "Performing base PingOne CIAM configuration"
echo "Environment ID is $ENV_ID"
echo "API URL path is $API_LOCATION"
echo "Current Org ID is $ORG_ID"
echo "CIAM worker token is $WORKER_APP_ACCESS_TOKEN"


#performing initial PingOne CIAM creation scripts
echo "Running CIAM creation scripts . . . . . . . . . ."
for script in ./Solutions/CIAM/PingOne/*create.sh; do
  echo "Executing $script..."
  bash $script 
done

echo "Running CIAM set scripts . !"
#performing initial PingOne CIAM set scripts
for script in ./Solutions/CIAM/PingOne/*set.sh; do
  echo "Executing $script..."
  bash $script 
done