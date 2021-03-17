#!/bin/bash

# creates sample user populations in PingOne

#Variables needed to be passed for this script:
# API_LOCATION
# ENV_ID
# WORKER_APP_ACCESS_TOKEN

#define script for job.
echo "------ Beginning 201-auth_pol_revert.sh ------"

# set global api call retry limit - this can be set to desired amount, default is 2
api_call_retry_limit=2

risk_pol_revert=0

def_set_ct=0
delete_ct=0

function sfa_def () {
  # Get Default Standard Authentication Policy to set back to default
  echo "Setting Single_Factor policy back to standard."
  SFA_POL_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies/" \
  --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
  | jq -r '._embedded.signOnPolicies[] | select(.name=="Single_Factor") | .id')

  #set Single Factor to default
  SFA_POL_DEFAULT=$(curl -s --location --request PUT "$API_LOCATION/environments/$ENV_ID/signOnPolicies/$SFA_POL_ID" \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
  --data-raw '{
    "name": "Single_Factor",
    "default": "true",
    "description": "A sign-on policy that requires username and password"
    }'
  )

  #limit retries
  def_set_ct=$((def_set_ct+1))
  sfa_def_verify
}

function sfa_def_verify () {
  #make sure Single is default again
  SFA_POL_DEF=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies/" \
  --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
  | jq -r '._embedded.signOnPolicies[] | select(.name=="Single_Factor") | .default')

  if [ "$SFA_POL_DEF" == "true" ]; then
    echo "Verified Single_Factor Auth policy is set to default..."
    get_delete_ids
    delete_ids
  elif [ "$SFA_POL_DEF" == "false" ] || [ -z ${SFA_POL_DEF+x} ] && [[ "$def_set_ct" > "$api_call_retry_limit" ]]; then
    sfa_def
  else
      echo "Single_Factor Auth not set successfully!"
      exit 1
  fi
}

function get_delete_ids () {
  # Get the Demo policy IDs
  #Get the SELF REG SFA ID
  echo "Getting policy IDs for deletion."
  SELF_POL_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
  --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
  | jq -rc '._embedded.signOnPolicies[] | select(.name=="Demo_Self-Registration_Login_Policy") | .id')
  #Get the SMS ID
  SMS_POL_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
  --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
  | jq -rc '._embedded.signOnPolicies[] | select(.name=="Demo_Passwordless_SMS_Login_Policy") | .id')
  #Get the passwordless ID
  ALL_MFA_POL_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
  --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
  | jq -rc '._embedded.signOnPolicies[] | select(.name=="Demo_Passwordless_Any_Method_Login_Policy") | .id')
  #Get the MFA ID
  MFA_POL_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
  --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
  | jq -rc '._embedded.signOnPolicies[] | select(.name=="Demo_Multi_Factor_Login_Policy") | .id')
}

function delete_ids () {
  #Delete the policies
  if [[ "$delete_ct" < "$api_call_retry_limit" ]]; then
    if [ -z ${SELF_POL_ID+x} ];then
      echo "Demo_Self-Registration_Login_Policy ID not found, retrying ID search."
      get_delete_ids
    else
      SELF_POL_DEL=$(curl -s --location --request DELETE "$API_LOCATION/environments/$ENV_ID/signOnPolicies/$SELF_POL_ID" \
      --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
      --data-raw '')
    fi
    if [ -z ${SMS_POL_ID+x} ];then
      echo "Demo_Passwordless_SMS_Login_Policy ID not found, retrying ID search."
      get_delete_ids
    else
      SMS_POL_DEL=$(curl -s --location --request DELETE "$API_LOCATION/environments/$ENV_ID/signOnPolicies/$SMS_POL_ID" \
      --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
      --data-raw '')
    fi
    if [ -z ${ALL_MFA_POL_ID+x} ];then
      echo "Demo_Passwordless_Any_Method_Login_Policy ID not found, retrying ID search."
      get_delete_ids
    else
      ALL_MFA_POL_DEL=$(curl -s --location --request DELETE "$API_LOCATION/environments/$ENV_ID/signOnPolicies/$ALL_MFA_POL_ID" \
      --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
      --data-raw '')
    fi
    if [ -z ${MFA_POL_ID+x} ];then
      echo "Demo_Multi_Factor_Login_Policy ID not found, retrying ID search."
      get_delete_ids
    else
      MFA_POL_DEL=$(curl -s --location --request DELETE "$API_LOCATION/environments/$ENV_ID/signOnPolicies/$MFA_POL_ID" \
      --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
      --data-raw '')
    fi
    return
  elif [[ "$delete_ct" > "$api_call_retry_limit" ]]; then
    echo "Demo policy deletion failed $delete_ct times. Exiting script."
    exit 1
  fi
  #limit retries
  delete_ct=$((delete_ct+1))

  #call validation function
  validate_delete
}

function validate_delete () {
  get_delete_ids
  echo $SELF_POL_ID
    if [ -z ${SELF_POL_ID+x} ] || [[ $SELF_POL_ID == *"NOT_FOUND"* ]];then
      echo "Demo_Self-Registration_Login_Policy ID deleted successfully."
    else
      delete_ids
    fi
    if [ -z ${SMS_POL_ID+x} ] || [[ $SMS_POL_ID == *"NOT_FOUND"* ]];then
      echo "Demo_Passwordless_SMS_Login_Policy ID deleted successfully."
    else
      delete_ids
    fi
    if [ -z ${ALL_MFA_POL_ID+x} ] || [[ $ALL_MFA_POL_ID == *"NOT_FOUND"* ]];then
      echo "Demo_Passwordless_Any_Method_Login_Policy ID deleted successfully."
    else
      delete_ids
    fi
    if [ -z ${MFA_POL_ID+x} ] || [[ $MFA_POL_ID == *"NOT_FOUND"* ]];then
      echo "Demo_Multi_Factor_Login_Policy ID deleted successfully."
    else
      delete_ids
    fi
}

#call it all.
sfa_def

#script finish
echo "------ End 201-auth_pol_revert.sh ------"