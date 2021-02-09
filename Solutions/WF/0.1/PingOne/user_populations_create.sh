#!/bin/bash

# creates sample user populations in PingOne

#Variables needed to be passed for this script:
# API_LOCATION=
# ENV_ID=
# CLIENT_ID=
# CLIENT_SECRET=

# get access token
WORKER_APP_ACCESS_TOKEN=$(curl -u $CLIENT_ID:$CLIENT_SECRET \
--location --request POST "https://auth.pingone.com/$ENV_ID/as/token" \
--header "Content-Type: application/x-www-form-urlencoded" \
--data-raw 'grant_type=client_credentials' \
| jq -r '.access_token')

# create sample employee population
POP1_CREATE=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/populations" \
--header 'content-type: application/json' \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '{
  "name" : "Sample Employee Population",
  "description" : "Sample Employee Population"
}')

# create sample contractor population
POP2_CREATE=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/populations" \
--header 'content-type: application/json' \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '{
  "name" : "Sample Contractor Population",
  "description" : "Sample Contractor Population"
}')

# get employee population ID
EMP_POP=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Sample Employee Population") | .id')

# create employee sample users
EMP_USER1=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/users" \
--header 'content-type: application/vnd.pingidentity.user.import+json' \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '{
    "email": "non-working-email@example.com",
    "name": {
        "given": "Bob",
        "family": "Smith"
    },
    "population": {
        "id": "'"$EMP_POP"'"
    },
    "username": "bsmith",
    "password": {
        "value": "2FederateM0re!",
        "forceChange": true
    }
}')

EMP_USER2=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/users" \
--header 'content-type: application/vnd.pingidentity.user.import+json' \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '{
    "email": "non-working-email@example.com",
    "name": {
        "given": "John",
        "family": "Schmidt"
    },
    "population": {
        "id": "'"$EMP_POP"'"
    },
    "username": "jschmidt",
    "password": {
        "value": "2FederateM0re!",
        "forceChange": true
    }
}')

EMP_USER3=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/users" \
--header 'content-type: application/vnd.pingidentity.user.import+json' \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '{
    "email": "non-working-email@example.com",
    "name": {
        "given": "Melanie",
        "family": "Holt"
    },
    "population": {
        "id": "'"$EMP_POP"'"
    },
    "username": "mholt",
    "password": {
        "value": "2FederateM0re!",
        "forceChange": true
    }
}')

EMP_USER4=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/users" \
--header 'content-type: application/vnd.pingidentity.user.import+json' \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '{
    "email": "non-working-email@example.com",
    "name": {
        "given": "Judith",
        "family": "Kelley"
    },
    "population": {
        "id": "'"$EMP_POP"'"
    },
    "username": "jkelley",
    "password": {
        "value": "2FederateM0re!",
        "forceChange": true
    }
}')

EMP_USER5=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/users" \
--header 'content-type: application/vnd.pingidentity.user.import+json' \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '{
    "email": "non-working-email@example.com",
    "name": {
        "given": "Tom",
        "family": "Bond"
    },
    "population": {
        "id": "'"$EMP_POP"'"
    },
    "username": "tbond",
    "password": {
        "value": "2FederateM0re!",
        "forceChange": true
    }
}')

# get contractor population ID
CON_POP=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Sample Contractor Population") | .id')

# create contract users
CON_USER1=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/users" \
--header 'content-type: application/vnd.pingidentity.user.import+json' \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '{
    "email": "non-working-email@example.com",
    "name": {
        "given": "Caleb",
        "family": "Harris"
    },
    "population": {
        "id": "'"$CON_POP"'"
    },
    "username": "charris",
    "password": {
        "value": "2FederateM0re!",
        "forceChange": true
    }
}')

CON_USER2=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/users" \
--header 'content-type: application/vnd.pingidentity.user.import+json' \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '{
    "email": "non-working-email@example.com",
    "name": {
        "given": "Kurt",
        "family": "Gregory"
    },
    "population": {
        "id": "'"$CON_POP"'"
    },
    "username": "kgregory",
    "password": {
        "value": "2FederateM0re!",
        "forceChange": true
    }
}')

CON_USER3=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/users" \
--header 'content-type: application/vnd.pingidentity.user.import+json' \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '{
    "email": "non-working-email@example.com",
    "name": {
        "given": "Emmett",
        "family": "Wilkins"
    },
    "population": {
        "id": "'"$CON_POP"'"
    },
    "username": "ewilkins",
    "password": {
        "value": "2FederateM0re!",
        "forceChange": true
    }
}')

CON_USER4=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/users" \
--header 'content-type: application/vnd.pingidentity.user.import+json' \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '{
    "email": "non-working-email@example.com",
    "name": {
        "given": "Stacey",
        "family": "Gomez"
    },
    "population": {
        "id": "'"$CON_POP"'"
    },
    "username": "sgomez",
    "password": {
        "value": "2FederateM0re!",
        "forceChange": true
    }
}')

CON_USER5=$(curl -s --location --request POST "$API_LOCATION/environments/$ENV_ID/users" \
--header 'content-type: application/vnd.pingidentity.user.import+json' \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
--data-raw '{
    "email": "non-working-email@example.com",
    "name": {
        "given": "Stephanie",
        "family": "Kelly"
    },
    "population": {
        "id": "'"$CON_POP"'"
    },
    "username": "skelly",
    "password": {
        "value": "2FederateM0re!",
        "forceChange": true
    }
}')

# Validate
# get users in employee population
EMP_USER_EXP_COUNT=5
EMP_USERS=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select (.name=="Sample Employee Population") | .userCount')

if [ $EMP_USERS == $EMP_USER_EXP_COUNT ]; then
    echo "Sample employee population created, all sample employee users created..."
else
    echo "Not all sample employee users were created, or population was not successfully created..."
    exit 1
fi

# Validate
# get users in contractor population
CON_USER_EXP_COUNT="5"
CON_USERS=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select (.name=="Sample Contractor Population") | .userCount')

if [ $CON_USERS == $CON_USER_EXP_COUNT ]; then
    echo "Sample contractor population created, all sample contractor users created..."
else
    echo "Not all sample contractor users were created, or population was not successfully created..."
    exit 1
fi