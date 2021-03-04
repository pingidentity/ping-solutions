#!/bin/bash

# creates sample user populations in PingOne

#Variables needed to be passed for this script:
# API_LOCATION
# ENV_ID
# WORKER_APP_ACCESS_TOKEN

#################################
#Get the default population ID
SELF_POP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
| jq -rc '._embedded.populations[] | select(.name=="Sample Users") | .id')

#create the new self-reg policy
echo "Creating self-registration policy"

SELF_POL_CREATE=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '{
  "name": "Demo_Self-Registration_Login_Policy",
  "default": "false",
  "description": "A sign-on policy that allows for single-factor self-registration for Demo purposes"
}')

#Get the new SELF REG SFA ID
SELF_POL_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
| jq -rc '._embedded.signOnPolicies[] | select(.name=="Demo_Self-Registration_Login_Policy") | .id')

#Create the self-reg action
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
}')

#moving on
echo "Creating passwordless SMS policy"
#create the new SMS auth policy
SMS_POL_CREATE=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '{
  "name": "Demo_Passwordless_SMS_Login_Policy",
  "default": "false",
  "description": "A passwordless sign-on policy that allows SMS authentication for Demo purposes"
}')

#Get the new SMS ID
SMS_POL_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
| jq -rc '._embedded.signOnPolicies[] | select(.name=="Demo_Passwordless_SMS_Login_Policy") | .id')

#Create the SMS action
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
  }')

#moving on again

#create the new passwordless any method Demo policy
echo "Creating any method passwordless policy"
ALL_MFA_POL_CREATE=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '{
  "name": "Demo_Passwordless_Any_Method_Login_Policy",
  "default": "false",
  "description": "A passwordless sign-on policy that allows for FIDO2 Biometrics, Authenticator app, email, SMS, or security key authentication for Demo purposes"
}')


#Get the new passwordless ID
ALL_MFA_POL_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/signOnPolicies" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
| jq -rc '._embedded.signOnPolicies[] | select(.name=="Demo_Passwordless_Any_Method_Login_Policy") | .id')


#Create the passwordless action
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
  }')

#moving on again

#create the new all-in step up Multi-factor Demo policy
echo "Creating Demo multi-factor policy policy"
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

#Create the action (pt 1 of 2)
MFA_ACTION_CREATE=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/signOnPolicies/$MFA_POL_ID/actions" \
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
}')

#Create the action (pt 2 of 2)
MFA_ACTION_CREATE=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/signOnPolicies/$MFA_POL_ID/actions" \
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
  }')