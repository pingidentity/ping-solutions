#!/bin/bash

# creates sample user populations in PingOne

#Variables needed to be passed for this script:
# API_LOCATION
# ENV_ID
# WORKER_APP_ACCESS_TOKEN

# get Sample Users population, id
SAMPLE_USERS_POP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Sample Users") | .id')

# check for Sample Users population ID
if [[ -z "$SAMPLE_USERS_POP_ID" ]] || [[ "$SAMPLE_USERS_POP_ID" == "" ]]; then
    echo "Sample Users population not found, no groups to delete..."
else
    # get ID of Sample Group
    SAMPLE_GROUP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/groups?filter=name%20eq%20%22Sample%20Group%22&limit=20" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    | jq -rc '._embedded.groups[] | select (.name=="Sample Group") | .id')

    # delete Sample Group, get status code of request
    DELETE_SAMPLE_GROUP=$(curl -s --write-out "%{http_code}\n" --location --request DELETE "$API_LOCATION/environments/$ENV_ID/groups/$SAMPLE_GROUP_ID" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN")
    DELETE_SAMPLE_GROUP_RESULT=$( echo $DELETE_SAMPLE_GROUP | sed 's@.*}@@' )

    # make sure deletion status code matches expectation
    if [ "$DELETE_SAMPLE_GROUP_RESULT" == "204" ]; then
        echo "Sample Group deleted successfully..."
    else
        echo "Sample Group NOT deleted successfully!"
        exit 1
    fi
fi

# get More Sample Users population, id
MORE_SAMPLE_USERS_POP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="More Sample Users") | .id')

# check for More Sample Users population ID
if [[ -z "$MORE_SAMPLE_USERS_POP_ID" ]] || [[ "$MORE_SAMPLE_USERS_POP_ID" == "" ]]; then
    echo "More Sample Users population not found, no groups to delete..."
else
    # get ID of Another Sample Group
    ANOTHER_SAMPLE_GROUP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/groups?filter=name%20eq%20%22Another%20Sample%20Group%22&limit=20" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    | jq -rc '._embedded.groups[] | select (.name=="Another Sample Group") | .id')

    # delete Sample Group, get status code of request
    DELETE_ANOTHER_SAMPLE_GROUP=$(curl -s --write-out "%{http_code}\n" --location --request DELETE "$API_LOCATION/environments/$ENV_ID/groups/$ANOTHER_SAMPLE_GROUP_ID" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN")
    DELETE_ANOTHER_SAMPLE_GROUP_RESULT=$( echo $DELETE_ANOTHER_SAMPLE_GROUP | sed 's@.*}@@' )

    # make sure deletion status code matches expectation
    if [ "$DELETE_ANOTHER_SAMPLE_GROUP_RESULT" == "204" ]; then
        echo "Another Sample Group deleted successfully..."
    else
        echo "Another Sample Group NOT deleted successfully!"
        exit 1
    fi
fi

USER_IDS=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/users" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" } | jq -rc '._embedded.users[] | .id')

for USER_ID in $USER_IDS; do

    USER_POP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/users/$USER_ID?expand=population" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '.population.id')

    if [[ "$USER_POP_ID" == "$SAMPLE_USERS_POP_ID" ]] || [[ "$USER_POP_ID" == "$MORE_SAMPLE_USERS_POP_ID" ]]; then

        DELETE_USER=$(curl -s --write-out "%{http_code}\n" --location --request DELETE "$API_LOCATION/environments/$ENV_ID/users/$USER_ID" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" --data-raw '')

        # check response code
        DELETE_USER_RESULT=$(echo $DELETE_USER | sed 's@.*}@@' )
        if [ "$DELETE_USER_RESULT" == "204" ]; then
            echo "Sample User $USER_ID was deleted..."
        else
            echo "Sample User $USER_ID NOT removed successfully!"
            exit 1
        fi
    else
        echo "$USER_ID is not in one of the sample user populations, skipping this user..."
    fi
done

# create default population - this is needed for successful removal of demo populations
CREATE_DEFAULT_POP=$(curl -s --write-out "%{http_code}\n" --location --request POST "$API_LOCATION/environments/$ENV_ID/populations" --header 'content-type: application/json' \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    --data-raw '{
    "name" : "Default Population",
    "description" : "Default population created from demo data removal process."
}')

# check response code
CREATE_DEFAULT_POP_RESULT=$(echo $CREATE_DEFAULT_POP | sed 's@.*}@@' )
if [ $CREATE_DEFAULT_POP_RESULT == "201" ] ; then
    echo "Default Populaton created successfully..."
else
    echo "Default Populaton NOT created successfully!"
    exit 1
fi

# check Sample Users
SAMPLE_USERS_POP_NAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Sample Users") | .name')

# get Sample Users population ID
SAMPLE_USERS_POP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Sample Users") | .id')

# check, delete Sample Users population
if [ "$SAMPLE_USERS_POP_NAME" == "Sample Users" ]; then
    echo "Existing Sample Users population found, removing..."

    # delete Sample Users population
    DELETE_SAMPLE_USERS_POP=$(curl -s --write-out "%{http_code}\n" --location --request DELETE "$API_LOCATION/environments/$ENV_ID/populations/$SAMPLE_USERS_POP_ID" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" --data-raw '')

    # check response code
    DELETE_SAMPLE_USERS_POP_RESULT=$(echo $DELETE_SAMPLE_USERS_POP | sed 's@.*}@@' )
    if [ $DELETE_SAMPLE_USERS_POP_RESULT == "204" ] ; then
        echo "Sample Users Populaton removed successfully..."
    else
        echo "Sample Users Populaton was NOT removed successfully!"
        exit 1
    fi

else
    echo "Expected Sample Users population does not currently exist, proceeding to next step..."
fi

# check More Sample Users
MORE_SAMPLE_USERS_POP_NAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="More Sample Users") | .name')

# get More Sample Users population ID
MORE_SAMPLE_USERS_POP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="More Sample Users") | .id')

# check, delete More Sample Users population
if [ "$MORE_SAMPLE_USERS_POP_NAME" == "More Sample Users" ]; then
    echo "Existing More Sample Users population found, removing..."

    # delete More Sample Users population
    DELETE_MORE_SAMPLE_USERS_POP=$(curl -s --write-out "%{http_code}\n" --location --request DELETE "$API_LOCATION/environments/$ENV_ID/populations/$MORE_SAMPLE_USERS_POP_ID" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" --data-raw '')

    # check response code
    DELETE_SAMPLE_USERS_POP_RESULT=$( echo $DELETE_MORE_SAMPLE_USERS_POP | sed 's@.*}@@' )
    if [ "$DELETE_SAMPLE_USERS_POP_RESULT" == "204" ] ; then
        echo "More Sample Users Populaton removed successfully..."
    else
        echo "More Sample Users Populaton was NOT removed successfully!"
        exit 1
    fi

else
    echo "Expected More Sample Users population does not currently exist, proceeding to next step..."
fi