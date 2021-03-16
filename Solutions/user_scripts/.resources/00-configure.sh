#!/bin/bash

#set the dir location
sol_dir="$(cd "$(dirname "$0")";cd ../../; pwd)"
#set the solution directory
script_dir="$(cd "$(dirname "$0")";cd ../../../.gitlab-ci; pwd)"
#set the cypress directory
cypress_dir="$(cd "$(dirname "$0")";cd ../../../cypress; pwd)"

#cleanup in case of failure
find "$cypress_dir"/integration/ -name *.js -type f -delete >> /dev/null
find "$script_dir" -name *.txt -type f -delete >> /dev/null
find "$cypress_dir" -name *.txt -type f -delete >> /dev/null


#Let's set up some variables in case someone new is running this. Much of this is done by pipeline or other resources
if [ -z ${API_LOCATION+x} ]; then 
    #not set, let's do it!
  export API_LOCATION='https://api.pingone.com/v1' 
fi
if [ -z ${DOMAIN+x} ]; then 
    #not set, let's do it!
  export DOMAIN='example.com' 
fi
if [ -z ${PINGFED_BASE_URL+x} ]; then 
    #not set, let's do it!
  export PINGFED_BASE_URL='https://localhost' 
fi
if [ -z ${CYPRESS_PROJECT_ID+x} ]; then 
    #not set, let's do it!
  export CYPRESS_PROJECT_ID='null'
fi

#make some assumptions on the type of licenses available. This may not cover everything.
if [[ $CONSOLE_USERNAME == "PDSolutions" ]]; then
  PING_LICENSE="INTERNAL"
elif [[ $CONSOLE_USERNAME == *"@pingidentity.com" ]]; then
  PING_LICENSE="INTERNAL"
elif [[ $CONSOLE_USERNAME != *"@pingidentity.com" ]]; then
  PING_LICENSE="PingOne for Customers Trial"
fi

#WORKFORCEEEEEEEEEEE
#setup the env name. echoing because something might not be set?
#using the cypress.d directory due to persisting between stages. Using epoch time for uniqueness.
if [[ $CONFIGURE_WF = true ]]; then
  if [ -e "$cypress_dir"/WF_ENV_NAME.txt ]; then
    echo "Setting Workforce environment value from user input."
    export WF_ENV_NAME=$(cat "$cypress_dir"/WF_ENV_NAME.txt)
  else
    echo "Setting Workforce environment value."
    date +"WF_DEMO_ENV_"%s > "$cypress_dir"/WF_ENV_NAME.txt
    export WF_ENV_NAME=$(cat "$cypress_dir"/WF_ENV_NAME.txt)
    if [ -z ${WF_ENV_NAME+x} ]; then echo "WF environment name is unset" && exit 1; else echo "WF environment name is $WF_ENV_NAME"; fi
  fi
fi

if [[ $CONFIGURE_CIAM = true ]]; then
  if [ -e "$cypress_dir"/CIAM_ENV_NAME.txt ]; then
    echo "Setting CIAM environment value from user input."
    export CIAM_ENV_NAME=$(cat "$cypress_dir"/CIAM_ENV_NAME.txt)
  else
    echo "Setting CIAM environment value."
    date +"CIAM_DEMO_ENV_"%s > "$cypress_dir"/CIAM_ENV_NAME.txt
    export CIAM_ENV_NAME=$(cat "$cypress_dir"/CIAM_ENV_NAME.txt)
    if [ -z ${CIAM_ENV_NAME+x} ]; then echo "CIAM environment name is unset" && exit 1; else echo "CIAM environment name is $CIAM_ENV_NAME"; fi
  fi
fi


if [ -z ${ADMIN_ENV_ID+x} ]; then echo "ENV ID is unset" && exit 1; else echo "Admin Environment ID is $ADMIN_ENV_ID"; fi
if [ -z ${CONSOLE_USERNAME+x} ]; then echo "Console username is unset" && exit 1; else echo "Console user is $CONSOLE_USERNAME"; fi
if [ -z ${CONSOLE_PASSWORD+x} ]; then echo "Console password is unset" && exit 1; else echo "Console password is set."; fi

if [[ $CYPRESS_PROJECT_ID -ne 'null' ]]; then
  echo "Cypress project ID is $CYPRESS_PROJECT_ID. Cypress key is $CYPRESS_RECORD_KEY"
fi

echo "Performing variable substitution"
#let's set this bad boy up!
#note: the ENV_ID up here is the master/admin ENV_ID for an environment, not the new. I'm going to forget about this.

echo "Setting up P14C environment"

#adding logic to allow choosing just WF or CIAM
if [[ $CONFIGURE_WF = true ]]; then
  cat "$script_dir"/cypress.d/base_files/env_files/create_WF_env.js | \
  sed -e "s/ENV_ID/$ADMIN_ENV_ID/g" -e "s/TEST_USERNAME/$CONSOLE_USERNAME/g" -e "s/TEST_PASSWORD/$CONSOLE_PASSWORD/g" -e "s/ENV_NM/$WF_ENV_NAME/g" -e "s/LIC_TYPE/$PING_LICENSE/g" > \
  "$cypress_dir"/integration/WF/01-create_wf_env.js

  cat "$script_dir"/cypress.d/base_files/env_files/create_worker_app.js | \
  sed -e "s/ENV_ID/$ADMIN_ENV_ID/g" -e "s/TEST_USERNAME/$CONSOLE_USERNAME/g" -e "s/TEST_PASSWORD/$CONSOLE_PASSWORD/g" -e "s/ENV_NM/$WF_ENV_NAME/g" \
  -e "s/PROD_NM/WF/g" -e "s@cypress_dir@./cypress@g" >> \
  "$cypress_dir"/integration/WF/01-create_wf_env.js
fi

#adding logic to allow choosing just WF or CIAM
if [[ $CONFIGURE_CIAM = true ]]; then
  cat "$script_dir"/cypress.d/base_files/env_files/create_CIAM_env.js | \
  sed -e "s/ENV_ID/$ADMIN_ENV_ID/g" -e "s/TEST_USERNAME/$CONSOLE_USERNAME/g" -e "s/TEST_PASSWORD/$CONSOLE_PASSWORD/g" -e "s/ENV_NM/$CIAM_ENV_NAME/g" -e "s/LIC_TYPE/$PING_LICENSE/g" > \
  "$cypress_dir"/integration/CIAM/02-create_ciam_env.js

  cat "$script_dir"/cypress.d/base_files/env_files/create_worker_app.js | \
  sed -e "s/ENV_ID/$ADMIN_ENV_ID/g" -e "s/TEST_USERNAME/$CONSOLE_USERNAME/g" -e "s/TEST_PASSWORD/$CONSOLE_PASSWORD/g" -e "s/ENV_NM/$CIAM_ENV_NAME/g" \
  -e "s/PROD_NM/CIAM/g" -e "s@cypress_dir@./cypress@g" >> \
  "$cypress_dir"/integration/CIAM/02-create_ciam_env.js
fi

cat "$script_dir"/cypress.d/base_files/env_files/cypress.json.base | sed -e "s/PID/$CYPRESS_PROJECT_ID/g" > "$cypress_dir"/../cypress.json

#lets crash and burn here if these don't exist
if [[ $CONFIGURE_WF = true ]]; then
  if [ ! -f "$cypress_dir"/integration/WF/01-create_wf_env.js ]; then
      echo "Variable substitution to set up WF environment not performed properly, exiting now..."
      exit 1
    else
      echo "Variable substitution to set up Workforce environment performed successfully."
  fi
fi

if [[ $CONFIGURE_CIAM = true ]]; then
  if [ ! -f "$cypress_dir"/integration/CIAM/02-create_ciam_env.js ]; then
    echo "Variable substitution to set up CIAM environment not performed properly, exiting now..."
    exit 1
    else
      echo "Variable substitution to set up CIAM environment performed successfully."
  fi
fi

#docker base options
DOCKER_RUN_OPTIONS="-i --rm"
# Only allocate tty if we detect one
if [ -t 0 ] && [ -t 1 ]; then
    DOCKER_RUN_OPTIONS="$DOCKER_RUN_OPTIONS -t"
fi

echo "Launching Docker to set up environment"

docker run $DOCKER_RUN_OPTIONS --ipc=host -v "$cypress_dir"/..:/e2e -w /e2e -entrypoint=cypress cypress/included:$CYPRESS_VERSION --browser chrome run 

find "$cypress_dir"/integration/ -name *.js -type f -delete

#set Ping One variables for WF
if [[ $CONFIGURE_WF = true ]]; then
  export CLIENT_ID=$(cat "$cypress_dir"/WF_client_id.txt)
  export CLIENT_SECRET=$(cat "$cypress_dir"/WF_client_secret.txt)
  export ENV_ID=$(cat "$cypress_dir"/WF_envid.txt)


  #get a worker app token to run our tests (WF)
  export WORKER_APP_ACCESS_TOKEN=$(curl -s -u $CLIENT_ID:$CLIENT_SECRET \
  --location --request POST "https://auth.pingone.com/$ENV_ID/as/token" \
  --header "Content-Type: application/x-www-form-urlencoded" \
  --data-raw 'grant_type=client_credentials' \
  | jq -r '.access_token')

  echo "Performing base PingOne WF configuration"
  echo "Environment ID is $ENV_ID"
  echo "API URL path is $API_LOCATION"

  echo "WF worker token is $WORKER_APP_ACCESS_TOKEN"

  #performing initial PingOne WF creation scripts
  echo "Running WF PingOne creation scripts."
  for script in "$sol_dir"/WF/PingOne/*set.sh; do
    echo "Executing configuration $script..."
    bash $script 
  done

  #performing initial PingOne WF creation scripts
  echo "Running WF PingFederate creation scripts."
  for script in "$sol_dir"/WF/PingFederate/*set.sh; do
    echo "Executing configuration $script..."
    bash $script 
  done
  
  #delete worker app
  if [[ $ENV_SCRIPT_CALLED == true ]];then
    WORKER_APP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
          --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select (.name=="app_runner_worker") | .id')
    WORKER_APP_DELETE=$(curl -s --location --request DELETE "$API_LOCATION/environments/$ENV_ID/applications/$WORKER_APP_ID" \
      --header 'Content-Type: application/json' --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" --data-raw '')
  fi
fi
#CCCCCCCCIIIIIIIIIAAAAAAAAAMMMMMMMMM

#set Ping One variables for CIAM
if [[ $CONFIGURE_CIAM = true ]]; then
  export CLIENT_ID=$(cat "$cypress_dir"/CIAM_client_id.txt)
  export CLIENT_SECRET=$(cat "$cypress_dir"/CIAM_client_secret.txt)
  export ENV_ID=$(cat "$cypress_dir"/CIAM_envid.txt)


  #get a worker app token to run our tests (WF)
  export WORKER_APP_ACCESS_TOKEN=$(curl -s -u $CLIENT_ID:$CLIENT_SECRET \
  --location --request POST "https://auth.pingone.com/$ENV_ID/as/token" \
  --header "Content-Type: application/x-www-form-urlencoded" \
  --data-raw 'grant_type=client_credentials' \
  | jq -r '.access_token')


  echo "Performing base PingOne CIAM configuration"
  echo "Environment ID is $ENV_ID"
  echo "API URL path is $API_LOCATION"
  echo "CIAM worker token is $WORKER_APP_ACCESS_TOKEN"

  #performing initial PingOne CIAM creation scripts
  echo "Running CIAM PingOne set scripts."
  #performing initial PingOne CIAM set scripts
  for script in "$sol_dir"/CIAM/PingOne/*set.sh; do
    echo "Executing configuration $script..."
    bash $script 
  done

  #performing initial PingOne WF creation scripts
  echo "Running CIAM PingFederate creation scripts."
  for script in "$sol_dir"/CIAM/PingFederate/*set.sh; do
    echo "Executing configuration $script..."
    bash $script 
  done

  #delete worker app if run by env_script
  if [[ $ENV_SCRIPT_CALLED == true ]];then
    WORKER_APP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
          --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select (.name=="app_runner_worker") | .id')
    WORKER_APP_DELETE=$(curl -s --location --request DELETE "$API_LOCATION/environments/$ENV_ID/applications/$WORKER_APP_ID" \
      --header 'Content-Type: application/json' --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" --data-raw '')
  fi
fi
