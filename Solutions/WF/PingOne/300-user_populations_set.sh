#!/bin/bash

# renames Sample Populations to WF use case examples

#Variables needed to be passed for this script:
# API_LOCATION
# ENV_ID
# WORKER_APP_ACCESS_TOKEN

# get Sample Users population name
SAMPLE_USERS_POP=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Sample Users") | .name')

# get More Sample Users population name
MORE_SAMPLE_USERS_POP=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="More Sample Users") | .name')

SAMPLE_POPS[0]="$SAMPLE_USERS_POP"
SAMPLE_POPS[1]="$MORE_SAMPLE_USERS_POP"

for SAMPLE_POP in "${SAMPLE_POPS[@]}"; do

    # check if name matches Sample Users population
    if [ "$SAMPLE_POP" == "Sample Users" ]; then

        # get sample users population ID
        SAMPLE_USERS_POP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Sample Users") | .id')

        # update More Sample Users population to contractors
        UPDATE_SAMPLE_USERS_POP=$(curl -s --write-out "%{http_code}\n" --location --request PUT "$API_LOCATION/environments/$ENV_ID/populations/$SAMPLE_USERS_POP_ID" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN"  --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
        --header 'Content-Type: application/json' \
        --data-raw '{
            "name" : "Contractors",
            "description" : "This is a sample contractor population."
        }')

        # check response code
        UPDATE_SAMPLE_USERS_POP_RESULT=$(echo $UPDATE_SAMPLE_USERS_POP | sed 's@.*}@@' )
        if [ "$UPDATE_SAMPLE_USERS_POP_RESULT" == "200" ] ; then

            # check for new population name
            SAMPLE_USERS_POP_NAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
            --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Contractors") | .name')

            # check if new sample population matches expected name, verifying sucessful update
            if [ "$SAMPLE_USERS_POP_NAME" == "Contractors" ]; then
                echo "Sample Users population successfully updated to contractors..."
            else
                echo "Sample Users population updated, however unable to verify new name change!"
            fi
        fi

    # check if name matches More Sample Users population
    elif [ "$SAMPLE_POP" == "More Sample Users" ]; then

        # get more sample users population ID
        MORE_SAMPLE_USERS_POP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="More Sample Users") | .id')

        # create another sample group based on More Sample Users population
        UPDATE_MORE_SAMPLE_USERS_POP=$(curl -s --write-out "%{http_code}\n" --location --request PUT "$API_LOCATION/environments/$ENV_ID/populations/$MORE_SAMPLE_USERS_POP_ID" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN"  --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
        --header 'Content-Type: application/json' \
        --data-raw '{
            "name" : "Employees",
            "description" : "This is a sample employee population."
        }')

        # check response code
        UPDATE_MORE_SAMPLE_USERS_POP_RESULT=$(echo $UPDATE_MORE_SAMPLE_USERS_POP | sed 's@.*}@@' )
        if [ "$UPDATE_MORE_SAMPLE_USERS_POP_RESULT" == "200" ] ; then

            # check for new population name
            MORE_SAMPLE_USERS_POP_NAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
            --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Employees") | .name')

            # check if new sample population matches expected name, verifying sucessful update
            if [ "$MORE_SAMPLE_USERS_POP_NAME" == "Employees" ]; then
                echo "More Sample Users population successfully updated to Employees..."
            else
                echo "More Sample Users population updated, however unable to verify new name change!"
            fi
        fi
    else
        echo "Sample Users population or More Sample Users population not found. Exiting..."
        exit 0
    fi
done
echo "Set User Populations checks and tasks completed."