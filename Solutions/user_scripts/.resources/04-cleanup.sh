#!/bin/bash

# Script to test PingOne instance against trial specifications
#set the dir location
sol_dir="$(cd "$(dirname "$0")";cd ../../; pwd)"
#set the solution directory
script_dir="$(cd "$(dirname "$0")";cd ../../../.gitlab-ci; pwd)"
#set the cypress directory
cypress_dir="$(cd "$(dirname "$0")";cd ../../../cypress; pwd)"

#Let's set up some variables in case someone new is running this. Much of this is done by pipeline or other resources
if [ -z ${API_LOCATION+x} ]; then 
    #not set, let's do it!
  API_LOCATION='https://api.pingone.com/v1' 
fi
if [ -z ${DOMAIN+x} ]; then 
    #not set, let's do it!
  DOMAIN='example.com' 
fi
if [ -z ${PINGFED_BASE_URL+x} ]; then 
    #not set, let's do it!
  PINGFED_BASE_URL='https://localhost' 
fi
if [ -z ${CYPRESS_PROJECT_ID+x} ]; then 
    #not set, let's do it!
  CYPRESS_PROJECT_ID='null'
fi

#setup the env name



echo "Performing env cleanup."
#set for our lovely local script since delete doesn't set either

export ENV_ID=$(cat "$cypress_dir"/WF_envid.txt)
export WF_ENV_NAME=$(cat "$cypress_dir"/WF_ENV_NAME.txt)

echo "Running variable substitution..."
cat "$script_dir"/cypress.d/base_files/env_files/delete_env.js | \
sed -e "s/ENV_ID/$ADMIN_ENV_ID/g" -e "s/TEST_USERNAME/$CONSOLE_USERNAME/g" -e "s/TEST_PASSWORD/$CONSOLE_PASSWORD/g" -e "s/ENV_NM/$WF_ENV_NAME/g" -e "s/PROD_NM/WF/g" > \
"$cypress_dir"/integration/WF/01-delete_env.js


cat "$script_dir"/cypress.d/base_files/env_files/cypress.json.base | sed -e "s/PID/$CYPRESS_PROJECT_ID/g" > "$cypress_dir"/../cypress.json

DOCKER_RUN_OPTIONS="-i --rm"
# Only allocate tty if we detect one
if [ -t 0 ] && [ -t 1 ]; then
    DOCKER_RUN_OPTIONS="$DOCKER_RUN_OPTIONS -t"
fi

echo "Performing environment revert via Docker..."
docker run $DOCKER_RUN_OPTIONS --ipc=host -v "$cypress_dir"/..:/e2e -w /e2e -entrypoint=cypress cypress/included:$CYPRESS_VERSION --browser chrome run

find "$cypress_dir"/integration/WF/ -name *.js -type f -delete
find "$cypress_dir"/ -name *.txt -type f -delete
