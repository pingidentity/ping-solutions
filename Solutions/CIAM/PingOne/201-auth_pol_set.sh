#!/bin/bash

# creates sample user populations in PingOne

#Variables needed to be passed for this script:
# API_LOCATION
# ENV_ID
# WORKER_APP_ACCESS_TOKEN

#define script for job.
echo "------ Beginning 201-auth_pol_set.sh ------"

# set global api call retry limit - this can be set to desired amount, default is 2
api_call_retry_limit=1

#set some individual counts
self_reg_ct=0
any_method_ct=0
passwordless_method_ct=0
mfa_ct=0

function def_pop_id () {
  #Get the default population ID
  SELF_POP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
  --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
  | jq -rc '._embedded.populations[] | select(.name=="Sample Users") | .id')

  check_existing_pols
}

#check for existing policies
function check_existing_pols() {

  SELF_REG_POL_NAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
  --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
  | jq -rc '._embedded.signOnPolicies[] | select(.name=="Demo_Self-Registration_Login_Policy") | .name')
  if [ "$SELF_REG_POL_NAME" != "Demo_Self-Registration_Login_Policy" ]; then
      self_reg_pol
  elif [ "$SELF_REG_POL_NAME" == "Demo_Self-Registration_Login_Policy" ]; then
    echo "Demo_Self-Registration_Login_Policy already exists!"
  fi

  SMS_POL_NAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
  --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
  | jq -rc '._embedded.signOnPolicies[] | select(.name=="Demo_Passwordless_SMS_Login_Policy") | .name')
  if [ "$SMS_POL_NAME" != "Demo_Passwordless_SMS_Login_Policy" ]; then
      passwordless_sms_pol
  elif [ "$SMS_POL_NAME" == "Demo_Passwordless_SMS_Login_Policy" ]; then
    echo "Demo_Passwordless_SMS_Login_Policy already exists!"
  fi

  ALL_MFA_POL_NAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
  --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
  | jq -rc '._embedded.signOnPolicies[] | select(.name=="Demo_Passwordless_Any_Method_Login_Policy") | .name')
  if [ "$ALL_MFA_POL_NAME" != "Demo_Passwordless_Any_Method_Login_Policy" ]; then
    any_method_passwordless_pol
  elif [ "$ALL_MFA_POL_NAME" == "Demo_Passwordless_Any_Method_Login_Policy" ]; then
    echo "Demo_Passwordless_Any_Method_Login_Policy already exists!"
  fi

  MFA_POL_NAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
  --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
  | jq -rc '._embedded.signOnPolicies[] | select(.name=="Demo_Multi_Factor_Login_Policy") | .name')
  if [ "$MFA_POL_NAME" != "Demo_Multi_Factor_Login_Policy" ]; then
    mfa_pol
  elif [ "$MFA_POL_NAME" == "Demo_Multi_Factor_Login_Policy" ]; then
    echo "Demo_Multi_Factor_Login_Policy already exists!"
  fi
}

function self_reg_pol () {

  #create the new self-reg policy
  echo "Creating self-registration policy."
  SELF_POL_CREATE=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
  --data-raw '{
    "name": "Demo_Self-Registration_Login_Policy",
    "default": "false",
    "description": "A sign-on policy that allows for single-factor self-registration for Demo purposes"
    }'
  )

    #Get the new SELF REG SFA ID
    SELF_POL_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    | jq -rc '._embedded.signOnPolicies[] | select(.name=="Demo_Self-Registration_Login_Policy") | .id')

  self_reg_action
}

function self_reg_action () {
  #Create the self-reg action
  if [ -z ${SELF_POL_ID+x} ] && [[ "$self_reg_ct" < "$api_call_retry_limit" ]]; then
    self_reg_pol
  elif [ -z ${SELF_POL_ID+x} ] && [[ "$self_reg_ct" < "$api_call_retry_limit" ]]; then
    self_reg_ct_left=$(api_call_retry_limit-self_reg_ct)
    echo "Demo_Self-Registration_Login_Policy could not be set, retrying $self_reg_ct_left more time(s)..."
    #limit retries
    self_reg_ct=$((self_reg_ct+1))
  fi
  #perform the curl action
  echo "Creating Demo_Self-Registration_Login_Policy action."
  SELF_ACTION_CREATE=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/signOnPolicies/$SELF_POL_ID/actions" \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
  --data-raw '{
    "priority": 1,
    "type": "LOGIN",
    "recovery": {
      "enabled": true
    },
    "registration": {
      "enabled": true,
      "population": {
        "id": "'"$SELF_POP_ID"'"
      }
    }
    }'
  )
  #validate function success
  self_action_val
}

function self_action_val () {
  SELF_ACTION_VAL=$(echo $SELF_ACTION_CREATE | jq -rc '.registration.enabled')
  if [[ $SELF_ACTION_VAL == true ]]; then
    echo "Demo_Self-Registration_Login_Policy set successfully"
  elif [ -z ${SELF_ACTION_VAL+x} ] && [[ "$self_reg_ct" < "$api_call_retry_limit" ]]; then
    self_reg_action
  else
    echo "Demo_Self-Registration_Login_Policy action could not be set, exiting script."
    exit 1
  fi
}

function passwordless_sms_pol () {
  #moving on
  echo "Creating passwordless SMS policy."
  #create the new SMS auth policy
  SMS_POL_CREATE=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
  --data-raw '{
    "name": "Demo_Passwordless_SMS_Login_Policy",
    "default": "false",
    "description": "A passwordless sign-on policy that allows SMS authentication for Demo purposes"
    }'
  )

  #Get the new SMS ID
  SMS_POL_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
  --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
  | jq -rc '._embedded.signOnPolicies[] | select(.name=="Demo_Passwordless_SMS_Login_Policy") | .id')

  #limit retries
  passwordless_method_ct=$((passwordless_method_ct+1))
  sms_action
}

function sms_action () {
  #Create the SMS action
  if [ -z ${SMS_POL_ID+x} ] && [[ "$passwordless_method_ct" < "$api_call_retry_limit" ]]; then
    passwordless_sms_pol
  elif [ -z ${SMS_POL_ID+x} ] && [[ "$passwordless_method_ct" > "$api_call_retry_limit" ]]; then
    echo "Demo_Passwordless_SMS_Login_Policy could not be set, exiting script."
    exit 1
  fi
  echo "Creating Demo_Passwordless_SMS_Login_Policy action."
  SMS_ACTION_CREATE=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/signOnPolicies/$SMS_POL_ID/actions" \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
  --data-raw '{
    "priority": 1,
    "type": "MULTI_FACTOR_AUTHENTICATION",
      "priority": 1,
      "noDevicesMode": "BLOCK",
      "sms": {
        "enabled": true
      },
      "boundBiometrics": {
        "enabled": false
      },
      "authenticator": {
        "enabled": false
      },
      "email": {
        "enabled": false
      },
      "securityKey": {
        "enabled": false
      }
    }'
  )
  #validate function success
  sms_action_val

}

function sms_action_val () {
  SMS_ACTION_VAL=$(echo $SMS_ACTION_CREATE | jq -rc '.sms.enabled')
  if [[ $SMS_ACTION_VAL == true ]]; then
    echo "Demo_Passwordless_SMS_Login_Policy set successfully"
  elif [ -z ${SMS_ACTION_VAL+x} ] && [[ "$passwordless_method_ct" < "$api_call_retry_limit" ]]; then
    sms_action
  else
    echo "Demo_Passwordless_SMS_Login_Policy action could not be set, exiting script."
    exit 1
  fi
}

function any_method_passwordless_pol () {
  #moving on again
  #create the new passwordless any method Demo policy
  echo "Creating any method passwordless policy."
  ALL_MFA_POL_CREATE=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
  --data-raw '{
    "name": "Demo_Passwordless_Any_Method_Login_Policy",
    "default": "false",
    "description": "A passwordless sign-on policy that allows for FIDO2 Biometrics, Authenticator app, email, SMS, or security key authentication for Demo purposes"
    }'
  )

  #Get the new passwordless ID
  ALL_MFA_POL_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
  --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
  | jq -rc '._embedded.signOnPolicies[] | select(.name=="Demo_Passwordless_Any_Method_Login_Policy") | .id')

  #limit retries
  any_method_ct=$((any_method_ct+1))
  any_method_passwordless_action
}

function any_method_passwordless_action () {
  #Create the passwordless action
  if [ -z ${ALL_MFA_POL_ID+x} ] && [[ "$any_method_ct" < "$api_call_retry_limit" ]]; then
    any_method_passwordless_pol
  elif [ -z ${ALL_MFA_POL_ID+x} ] && [[ "$any_method_ct" > "$api_call_retry_limit" ]]; then
    echo "Demo_Passwordless_Any_Method_Login_Policy could not be set, exiting script."
    exit 1
  fi
  echo "Creating Demo_Passwordless_Any_Method_Login_Policy action."
  ALL_MFA_ACTION_CREATE=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/signOnPolicies/$ALL_MFA_POL_ID/actions" \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
  --data-raw '{
    "priority": 30,
    "type": "MULTI_FACTOR_AUTHENTICATION",
      "priority": 1,
      "noDevicesMode": "BLOCK",
      "sms": {
        "enabled": true
      },
      "boundBiometrics": {
        "enabled": true
      },
      "authenticator": {
        "enabled": true
      },
      "email": {
        "enabled": true
      },
      "securityKey": {
        "enabled": true
      }
    }'
  )
  #validate function success
  any_method_action_val

}

function any_method_action_val () {
  ALL_MFA_ACTION_VAL=$(echo $ALL_MFA_ACTION_CREATE | jq -rc '.sms.enabled')
  if [[ $ALL_MFA_ACTION_VAL == true ]]; then
    echo "Demo_Passwordless_Any_Method_Login_Policy set successfully"
  elif [ -z ${ALL_MFA_ACTION_VAL+x} ] && [[ "$any_method_ct" < "$api_call_retry_limit" ]]; then
    sms_action
  else
    echo "Demo_Passwordless_Any_Method_Login_Policy action could not be set, exiting script."
    exit 1
  fi
}

function mfa_pol () {
  #moving on again
  #create the new all-in step up Multi-factor Demo policy
  echo "Creating Demo multi-factor policy policy."
  MFA_POL_CREATE=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
  --data-raw '{
    "name": "Demo_Multi_Factor_Login_Policy",
    "default": "false",
    "description": "A sign-on policy that requires primary username and password along with pre-configured additions for Demo purposes"
  }')


  #Get the new MFA ID
  MFA_POL_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
  --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
  | jq -rc '._embedded.signOnPolicies[] | select(.name=="Demo_Multi_Factor_Login_Policy") | .id')

  #limit retries
  mfa_ct=$((mfa_ct+1))
  mfa_action_1
}

function mfa_action_1 () {
  #Create the action (pt 1 of 2)
  if [ -z ${MFA_POL_ID+x} ] && [[ "$mfa_ct" < "$api_call_retry_limit" ]]; then
    mfa_pol
  elif [ -z ${MFA_POL_ID+x} ] && [[ "$mfa_ct" > "$api_call_retry_limit" ]]; then
    echo "Demo_Multi_Factor_Login_Policy could not be set, exiting script."
    exit 1
  fi
  echo "Creating Demo_Multi_Factor_Login_Policy action 1."
  MFA_ACTION_CREATE1=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/signOnPolicies/$MFA_POL_ID/actions" \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
  --data-raw '{
    "priority": 1,
    "type": "LOGIN",
    "recovery": {
      "enabled": true
    },
    "registration": {
      "enabled": true,
      "population": {
        "id": "'"$SELF_POP_ID"'"
        }
      }
    }'
  )
  mfa_action1_val

}

function mfa_action1_val () {
  MFA_ACTION1_VAL=$(echo $MFA_ACTION_CREATE1 | jq -rc '.registration.enabled')
  if [[ $MFA_ACTION1_VAL == true ]]; then
    echo "Demo_Multi_Factor_Login_Policy action 1 set successfully"
    mfa_action_2
  elif [ -z ${MFA_ACTION1_VAL+x} ] && [[ "$mfa_ct" < "$api_call_retry_limit" ]]; then
    mfa_action_1
  else
    echo "Demo_Multi_Factor_Login_Policy action 1 could not be set, exiting script."
    exit 1
  fi
}

function mfa_action_2 () {
#Create the action (pt 2 of 2)
  echo "Creating Demo_Multi_Factor_Login_Policy action 2."
  MFA_ACTION_CREATE2=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/signOnPolicies/$MFA_POL_ID/actions" \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
  --data-raw '{
    "priority": 2,
    "type": "MULTI_FACTOR_AUTHENTICATION",
    "condition": {
        "secondsSince": "${session.lastSignOn.withAuthenticator.mfa.at}",
        "greater": 300
        },
      "priority": 2,
      "noDevicesMode": "BLOCK",
      "sms": {
        "enabled": true
        },
      "boundBiometrics": {
        "enabled": true
        },
      "authenticator": {
        "enabled": true
        },
      "email": {
        "enabled": true
        },
      "securityKey": {
        "enabled": true
        }
    }'
  )
}

function mfa_action2_val () {
  MFA_ACTION2_VAL=$(echo $MFA_ACTION_CREATE2 | jq -rc '.sms.enabled')
  if [[ $MFA_ACTION2_VAL == true ]]; then
    echo "Demo_Passwordless_SMS_Login_Policy set successfully"
  elif [ -z ${MFA_ACTION2_VAL+x} ] && [[ "$mfa_ct" < "$api_call_retry_limit" ]]; then
    sms_action
  else
    echo "Demo_Passwordless_SMS_Login_Policy action could not be set, exiting script."
    exit 1
  fi
}

#call the functions
def_pop_id

#script finish
echo "------ End 201-auth_pol_set.sh ------"