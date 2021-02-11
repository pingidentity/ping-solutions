#!/bin/bash

# creates sample user populations in PingOne

#Variables needed to be passed for this script:
# API_LOCATION=
# ENV_ID=
# CLIENT_ID=
# CLIENT_SECRET=

# get employee population ID
EMP_POP=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Sample Employee Population") | .id')

# get users in employee population
EMP_USERS=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/users" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.users[] | select(.population.id=="'"$EMP_POP"'") | .id')

# for each user in employee population, remove them
for EMP_USER in $EMP_USERS;
do
    DELETE_EMP_USER=$(curl -s --location --request DELETE "$API_LOCATION/environments/$ENV_ID/users/$EMP_USER" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    --data-raw '')

done

# get contractor population ID
CON_POP=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Sample Contractor Population") | .id')

# get users in employee population
CON_USERS=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/users" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.users[] | select(.population.id=="'"$CON_POP"'") | .id')

# for each user in employee population, remove them
for CON_USER in $CON_USERS;
do
    DELETE_CON_USER=$(curl -s --location --request DELETE "$API_LOCATION/environments/$ENV_ID/users/$CON_USER" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    --data-raw '')

done

# Validate removal
# get users in employee population
EMP_USERS=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select (.name=="Sample Employee Population") | .userCount')

if [ -z $EMP_USERS ] || (( $EMP_USERS == 0 )); then
    echo "All sample employees removed..."
else
    echo "Not all sample employee users were removed..."
    exit 1
fi

# Validate removal
# get users in contractor population
CON_USER_EXP_COUNT=0
CON_USERS=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select (.name=="Sample Contractor Population") | .userCount')

if [ -z $CON_USERS ] || (( $CON_USERS == $CON_USER_EXP_COUNT )); then
    echo "All sample contractors removed..."
else
    echo "Not all sample contractor users were removed..."
    exit 1
fi

# get employee population ID
DELETE_EMP_POP=$(curl -s --location --request DELETE "$API_LOCATION/environments/$ENV_ID/populations/$EMP_POP" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN")

EMP_POP=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Sample Employee Population") | .id')

if [ -z $EMP_POP ]; then
    echo "Sample Employee Population removed..."
else
    echo "Sample Employee Population was not removed..."
    exit 1
fi

# get contractor population ID
DELETE_CON_POP=$(curl -s --location --request DELETE "$API_LOCATION/environments/$ENV_ID/populations/$CON_POP" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN")

CON_POP=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Sample Contractor Population") | .id')

if [ -z $CON_POP ]; then
    echo "Sample Contractor Population removed..."
else
    echo "Sample Contractor Population was not removed..."
    exit 1
fi