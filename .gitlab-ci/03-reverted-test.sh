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
if [ -z ${CONFIGURE_CIAM+x} ]; then 
    #not set, let's do it!
  CONFIGURE_CIAM=true
fi
if [ -z ${CONFIGURE_WF+x} ]; then 
    #not set, let's do it!
  CONFIGURE_WF=true
fi

#setup the env name
export WF_ENV_NAME=$(cat "$script_dir"/cypress.d/WF_ENV_NAME.txt)
export CIAM_ENV_NAME=$(cat "$script_dir"/cypress.d/CIAM_ENV_NAME.txt)

#set Ping One variables for WF
if [ $CONFIGURE_WF = true ]; then
    export CLIENT_ID=$(cat "$script_dir"/cypress.d/WF_client_id.txt)
    export CLIENT_SECRET=$(cat "$script_dir"/cypress.d/WF_client_secret.txt)
    export ENV_ID=$(cat "$script_dir"/cypress.d/WF_envid.txt)

    echo "Performing tests on reverted state."
    echo "Running variable substitution..."
    for script in "$script_dir"/cypress.d/cypress/base_files/WF/*revert.base; do
        echo "Modifying $script..."
        new_script_nm=$(echo $script | sed -e "s/revert.base/revert.js/g" -e "s@base_files@integration@g")
        cat $script | \
        sed -e "s/ENV_ID/$ADMIN_ENV_ID/g" -e "s/TEST_USERNAME/$CONSOLE_USERNAME/g" -e "s/TEST_PASSWORD/$CONSOLE_PASSWORD/g" -e "s/ENV_NM/$WF_ENV_NAME/g" > \
        "$new_script_nm"
    done
fi

#set Ping One variables for CIAM
if [ $CONFIGURE_CIAM = true ]; then
    export CLIENT_ID=$(cat "$script_dir/cypress.d/CIAM_client_id.txt")
    export CLIENT_SECRET=$(cat "$script_dir/cypress.d/CIAM_client_secret.txt")
    export ENV_ID=$(cat "$script_dir/cypress.d/CIAM_envid.txt")

    #echo "Performing tests on configured state."
    echo "Performing CIAM variable substitution..."
    for script in "$script_dir"/cypress.d/cypress/base_files/CIAM/*revert.base; do
        echo "Executing $script..."
        new_script_nm=$(echo $script | sed -e "s/revert.base/revert.js/g" -e "s@base_files@integration@g")
        cat $script | \
        sed -e "s/ENV_ID/$ADMIN_ENV_ID/g" -e "s/TEST_USERNAME/$CONSOLE_USERNAME/g" -e "s/TEST_PASSWORD/$CONSOLE_PASSWORD/g" -e "s/ENV_NM/$CIAM_ENV_NAME/g" > \
        "$new_script_nm"
    done
fi


cat "$script_dir/cypress.d/cypress/base_files/runner_tests/cypress.json.base" | sed -e "s/PID/$CYPRESS_PROJECT_ID/g" > "$script_dir/cypress.d/cypress.json"


DOCKER_RUN_OPTIONS="-i --rm"
# Only allocate tty if we detect one
if [ -t 0 ] && [ -t 1 ]; then
    DOCKER_RUN_OPTIONS="$DOCKER_RUN_OPTIONS -t"
fi

echo "Performing validation on reverted state."
#allow running if cypress stuff isn't defined
if [ -z ${CYPRESS_RECORD_KEY+x} ]; then 
    docker run $DOCKER_RUN_OPTIONS --ipc=host -v "$script_dir"/cypress.d:/e2e -w /e2e -entrypoint=cypress cypress/included:$CYPRESS_VERSION --browser chrome run
 
else 
    docker run $DOCKER_RUN_OPTIONS --ipc=host -v "$script_dir"/cypress.d:/e2e -w /e2e -entrypoint=cypress cypress/included:$CYPRESS_VERSION --browser chrome run --record --key $CYPRESS_RECORD_KEY
fi

#cleanup files for next stages
files_removed=$(echo "$script_dir/cypress.d/cypress/integration/")
find "$files_removed" -name *.js -type f -delete
