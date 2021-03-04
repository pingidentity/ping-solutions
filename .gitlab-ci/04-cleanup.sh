#!/bin/bash
# Script to test PingOne instance against trial specifications
#set the dir location
script_dir="$(cd "$(dirname "$0")"; pwd)"

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
#set Ping One variables for WF variable sub
if [[ $CONFIGURE_WF = true ]]; then
    export ENV_ID=$(cat "$script_dir"/cypress.d/WF_envid.txt)
    export WF_ENV_NAME=$(cat "$script_dir"/cypress.d/WF_ENV_NAME.txt)


    #"Note: If pipeline does not succeed this may error if things are not already configured, we want to run it regardless just in case."

    echo "Running WF variable substitution..."
    cat "$script_dir"/cypress.d/cypress/base_files/env_files/delete_env.base | \
    sed -e "s/ENV_ID/$ADMIN_ENV_ID/g" -e "s/TEST_USERNAME/$CONSOLE_USERNAME/g" -e "s/TEST_PASSWORD/$CONSOLE_PASSWORD/g" -e "s/ENV_NM/$WF_ENV_NAME/g" -e "s/PROD_NM/WF/g" > \
    "$script_dir"/cypress.d/cypress/integration/WF/01-delete_WF_env.js
fi

#set Ping One variables for CIAM variable sub
if [[ $CONFIGURE_CIAM = true ]]; then
    export ENV_ID=$(cat "$script_dir"/cypress.d/CIAM_envid.txt)
    export CIAM_ENV_NAME=$(cat "$script_dir"/cypress.d/CIAM_ENV_NAME.txt)

    echo "Running CIAM variable substitution..."
    cat "$script_dir"/cypress.d/cypress/base_files/env_files/delete_env.base | \
    sed -e "s/ENV_ID/$ADMIN_ENV_ID/g" -e "s/TEST_USERNAME/$CONSOLE_USERNAME/g" -e "s/TEST_PASSWORD/$CONSOLE_PASSWORD/g" -e "s/ENV_NM/$CIAM_ENV_NAME/g" -e "s/PROD_NM/CIAM/g" > \
    "$script_dir"/cypress.d/cypress/integration/CIAM/02-delete_CIAM_env.js
fi

#sep for our lovely local script since delete doesn't set either
if [ -z ${CONFIGURE_WF+x} ] && [ -z ${CONFIGURE_CIAM+x} ]; then 
    export ENV_ID=$(cat "$script_dir"/cypress.d/WF_envid.txt)
    export WF_ENV_NAME=$(cat "$script_dir"/cypress.d/WF_ENV_NAME.txt)

    echo "Running variable substitution..."
    cat "$script_dir"/cypress.d/cypress/base_files/env_files/delete_env.base | \
    sed -e "s/ENV_ID/$ADMIN_ENV_ID/g" -e "s/TEST_USERNAME/$CONSOLE_USERNAME/g" -e "s/TEST_PASSWORD/$CONSOLE_PASSWORD/g" -e "s/ENV_NM/$WF_ENV_NAME/g" -e "s/PROD_NM/WF/g" > \
    "$script_dir"/cypress.d/cypress/integration/WF/01-delete_env.js
fi

cat "$script_dir"/cypress.d/cypress/base_files/env_files/cypress.json.base | sed -e "s/PID/$CYPRESS_PROJECT_ID/g" > "$script_dir"/cypress.d/cypress.json

DOCKER_RUN_OPTIONS="-i --rm"
# Only allocate tty if we detect one
if [ -t 0 ] && [ -t 1 ]; then
    DOCKER_RUN_OPTIONS="$DOCKER_RUN_OPTIONS -t"
fi

echo "Performing environment revert via Docker..."
docker run $DOCKER_RUN_OPTIONS --ipc=host -v "$script_dir"/cypress.d:/e2e -w /e2e -entrypoint=cypress cypress/included:6.3.0 --browser chrome run

if [[ $CONFIGURE_WF = true ]]; then
    find "$script_dir"/cypress.d/cypress/integration/WF/ -name *.js -type f -delete
    find "$script_dir"/cypress.d/ -name *.txt -type f -delete
fi
if [[ $CONFIGURE_CIAM = true ]]; then
    find "$script_dir"/cypress.d/cypress/integration/CIAM/ -name *.js -type f -delete 
    find "$script_dir"/cypress.d/ -name *.txt -type f -delete
fi

if [ -z ${CONFIGURE_WF+x} ] && [ -z ${CONFIGURE_CIAM+x} ]; then 
    find "$script_dir"/cypress.d/cypress/integration/ -name *.js -type f -delete
    find "$script_dir"/cypress.d/ -name *.txt -type f -delete
fi
