#!/bin/bash

# creates two sample groups based on the sample users auto-generated for trials
#Variables needed to be passed for this script:
# API_LOCATION
# ENV_ID
# WORKER_APP_ACCESS_TOKEN

# get Sample Users population, id
SAMPLE_USERS_POP=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Sample Users") | .id')

# check if sample users population is present, create groups based on sample users population
if [[ -z "$SAMPLE_USERS_POP" ]] || [[ "$SAMPLE_USERS_POP" == "" ]]; then
    echo "Sample Users population does not exist initially, exiting..."
else
    # making sure sample users population ID contains no whitespace
    SAMPLE_USERS_POP_ID=$(echo $SAMPLE_USERS_POP | sed -e 's/ //g' )
    echo "Sample Users population found. Adding these users to Sample Group..."

    # create sample group based on Sample Users population
    CREATE_SAMPLE_GROUP=$(curl -s --write-out "%{http_code}\n" --location --request POST "$API_LOCATION/environments/$ENV_ID/groups" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "name" : "Sample Group",
        "description" : "This is a sample group based on the Sample Users population.",
        "userFilter": "population.id eq \"'"$SAMPLE_USERS_POP_ID"'\""
    }')

    # check response code
    CREATE_SAMPLE_GROUP_RESULT=$(echo $CREATE_SAMPLE_GROUP | sed 's@.*}@@' )
    if [ $CREATE_SAMPLE_GROUP_RESULT == "201" ] ; then

        # check sample group name
        CHECK_SAMPLE_GROUP=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/groups?filter=name%20eq%20%22Sample%20Group%22&limit=20" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
        | jq -rc '._embedded.groups[] | select (.name=="Sample Group") | .name')

        # check if sample group matches expected name, verifying sucessful creation
        if [ "$CHECK_SAMPLE_GROUP" == "Sample Group" ]; then
            echo "Sample Group created successfully..."
        else
            echo "Sample Group did NOT create successfully!"
            exit 1
        fi
    else
        echo "Sample Group did NOT create successfully, or already exists..."
    fi
fi

# get More Sample Users population
MORE_SAMPLE_USERS_POP=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="More Sample Users") | .id')

# check if more sample users population is present, create groups based on more sample users population
if [[ -z "$MORE_SAMPLE_USERS_POP" ]] || [[ "$MORE_SAMPLE_USERS_POP" == "" ]]; then
    echo "More Sample Users population does not exist initially, exiting..."
else
    # making sure more sample users population ID contains no whitespace
    MORE_SAMPLE_USERS_POP_ID=$(echo $MORE_SAMPLE_USERS_POP | sed -e 's/ //g' )
    echo "More Sample Users population found. Adding these users to Another Sample Group..."

    # create another sample group based on More Sample Users population
    CREATE_ANOTHER_SAMPLE_GROUP=$(curl -s --write-out "%{http_code}\n" --location --request POST "$API_LOCATION/environments/$ENV_ID/groups" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN"  --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "name" : "Another Sample Group",
        "description" : "This is a sample group based on the More Sample Users population.",
        "userFilter": "population.id eq \"'"$MORE_SAMPLE_USERS_POP_ID"'\""
    }')

    # check response code
    CREATE_ANOTHER_SAMPLE_GROUP_RESULT=$(echo $CREATE_ANOTHER_SAMPLE_GROUP | sed 's@.*}@@' )
    if [ "$CREATE_SAMPLE_GROUP_RESULT" == "201" ] ; then

        # check sample group name
        CHECK_ANOTHER_SAMPLE_GROUP=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/groups?filter=name%20eq%20%22Another%20Sample%20Group%22&limit=20" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
        | jq -rc '._embedded.groups[] | select (.name=="Another Sample Group") | .name')

        # check if sample group matches expected name, verifying sucessful creation
        if [ "$CHECK_ANOTHER_SAMPLE_GROUP" == "Another Sample Group" ]; then
            echo "Another Sample Group created successfully..."
        else
            echo "Another Sample Group did NOT create successfully!"
            exit 1
        fi
    else
        echo "Another Sample Group did NOT create successfully, or already exists..."
    fi
fi

echo "Set User Populations checks and tasks completed."