#!/bin/bash
# Script to configure PingOne instance to trial specifications

echo "Starting 00-base-configuration-work.sh"

#set the dir location
script_dir="$(cd "$(dirname "$0")"; pwd)"
#set the solution directory
sol_dir="$(cd "$(dirname "$0")";cd ../Solutions; pwd)"
#set the cypress directory
cypress_dir=$(echo "$script_dir/../cypress")
#cleanup in case of failure
find "$cypress_dir"/integration/ -name *.js -type f -delete
find "$script_dir" -name *.txt -type f -delete


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

if [[ $CONSOLE_USERNAME == "PDSolutions" ]]; then
  PING_LICENSE="INTERNAL"
elif [[ $CONSOLE_USERNAME == *"@pingidentity.com" ]]; then
  PING_LICENSE="INTERNAL"
elif [[ $CONSOLE_USERNAME != *"@pingidentity.com" ]]; then
  PING_LICENSE="PingOne for Customers Trial"
fi

#WORKFORCEEEEEEEEEEE

echo "Setting Workforce environment value."
date +"WF_DEMO_ENV_"%s > "$cypress_dir"/WF_ENV_NAME.txt
export WF_ENV_NAME=$(cat "$cypress_dir"/WF_ENV_NAME.txt)
if [ -z ${WF_ENV_NAME+x} ]; then echo "WF environment name is unset" && exit 1; else echo "WF environment name is $WF_ENV_NAME"; fi



echo "Setting CIAM environment value."
date +"CIAM_DEMO_ENV_"%s > "$cypress_dir/CIAM_ENV_NAME.txt"
export CIAM_ENV_NAME=$(cat "$cypress_dir/CIAM_ENV_NAME.txt")
if [ -z ${CIAM_ENV_NAME+x} ]; then echo "CIAM environment name is unset" && exit 1; else echo "CIAM environment name is $CIAM_ENV_NAME"; fi


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

cat "$script_dir"/cypress.d/base_files/env_files/create_env.js | \
sed -e "s/ENV_ID/$ADMIN_ENV_ID/g" -e "s/TEST_USERNAME/$CONSOLE_USERNAME/g" -e "s/TEST_PASSWORD/$CONSOLE_PASSWORD/g" -e "s/ENV_NM/$WF_ENV_NAME/g" -e "s/LIC_TYPE/$PING_LICENSE/g" > \
"$cypress_dir"/integration/WF/02-create_wf_env.js

cat "$script_dir"/cypress.d/base_files/env_files/create_worker_app.js | \
sed -e "s/ENV_ID/$ADMIN_ENV_ID/g" -e "s/TEST_USERNAME/$CONSOLE_USERNAME/g" -e "s/TEST_PASSWORD/$CONSOLE_PASSWORD/g" -e "s/ENV_NM/$WF_ENV_NAME/g" \
-e "s/PROD_NM/WF/g" -e "s@cypress_dir@$cypress_dir@g" > \
"$cypress_dir"/integration/WF/03-create_wf_worker_app.js

 cat "$script_dir"/cypress.d/base_files/env_files/create_env.js | \
 sed -e "s/ENV_ID/$ADMIN_ENV_ID/g" -e "s/TEST_USERNAME/$CONSOLE_USERNAME/g" -e "s/TEST_PASSWORD/$CONSOLE_PASSWORD/g" -e "s/ENV_NM/$CIAM_ENV_NAME/g" -e "s/LIC_TYPE/$PING_LICENSE/g" > \
 "$cypress_dir"/integration/CIAM/04-create_ciam_env.js

cat "$script_dir"/cypress.d/base_files/env_files/create_worker_app.js | \
sed -e "s/ENV_ID/$ADMIN_ENV_ID/g" -e "s/TEST_USERNAME/$CONSOLE_USERNAME/g" -e "s/TEST_PASSWORD/$CONSOLE_PASSWORD/g" -e "s/ENV_NM/$CIAM_ENV_NAME/g" \
-e "s/PROD_NM/CIAM/g" -e "s@cypress_dir@$cypress_dir@g" > \
"$cypress_dir"/integration/CIAM/05-create_ciam_worker_app.js

cat "$script_dir"/cypress.d/base_files/env_files/cypress.json.base | sed -e "s/PID/$CYPRESS_PROJECT_ID/g" > "$cypress_dir"/../cypress.json

#lets crash and burn here if these don't exist
if [[ $CONFIGURE_WF = true ]]; then
  if [ ! -f "$cypress_dir"/integration/WF/02-create_wf_env.js ] || \
  [ ! -f "$cypress_dir"/integration/WF/03-create_wf_worker_app.js ]; then
      echo "Variable substitution to set up WF environment not performed properly, exiting now..."
      exit 1
    else
      echo "Variable substitution to set up Workforce environment performed successfully."
  fi
fi

if [[ $CONFIGURE_CIAM = true ]]; then
  if [ ! -f "$cypress_dir"/integration/CIAM/04-create_ciam_env.js ] ||  \
  [ ! -f "$cypress_dir"/integration/CIAM/05-create_ciam_worker_app.js ]; then
    echo "Variable substitution to set up CIAM environment not performed properly, exiting now..."
    exit 1
    else
      echo "Variable substitution to set up CIAM environment performed successfully."
  fi
fi

echo "Finished 00-base-configuration-work.sh"