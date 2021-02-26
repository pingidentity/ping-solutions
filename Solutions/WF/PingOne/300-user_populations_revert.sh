#!/bin/bash

# renames WF use case populations back to default

#Variables needed to be passed for this script:
# API_LOCATION
# ENV_ID
# WORKER_APP_ACCESS_TOKEN

# get Sample Users population name
CONTRACTOR_POP=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Contractors") | .name')

# get More Sample Users population name
EMPLOYEE_POP=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Employees") | .name')

SAMPLE_POPS[0]="$CONTRACTOR_POP"
SAMPLE_POPS[1]="$EMPLOYEE_POP"

for SAMPLE_POP in "${SAMPLE_POPS[@]}"; do

    # check if name matches Sample Users population
    if [ "$SAMPLE_POP" == "Contractors" ]; then

        # get sample users population ID
        CONTRACTOR_POP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Contractors") | .id')

        # update More Sample Users population to contractors
        UPDATE_SAMPLE_USERS_POP=$(curl -s --write-out "%{http_code}\n" --location --request PUT "$API_LOCATION/environments/$ENV_ID/populations/$CONTRACTOR_POP_ID" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN"  --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
        --header 'Content-Type: application/json' \
        --data-raw '{
            "name" : "Sample Users",
            "description" : "This is a sample population."
        }')

        # check response code
        UPDATE_SAMPLE_USERS_POP_RESULT=$(echo $UPDATE_SAMPLE_USERS_POP | sed 's@.*}@@' )
        if [ "$UPDATE_SAMPLE_USERS_POP_RESULT" == "200" ] ; then

            # check for new population name
            SAMPLE_USERS_POP_NAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
            --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Sample Users") | .name')

            # check if new sample population matches expected name, verifying sucessful update
            if [ "$SAMPLE_USERS_POP_NAME" = "Sample Users" ]; then
                echo "Contractors population successfully reverted to Sample Users population..."
            else
                echo "Contractors population successfully reverted to Sample Users population, however unable to verify new name change!"
            fi
        fi

    # check if name matches More Sample Users population
    elif [ "$SAMPLE_POP" == "Employees" ]; then

        # get more sample users population ID
        EMPLOYEE_POP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Employees") | .id')

        # create another sample group based on More Sample Users population
        UPDATE_EMPLOYEE_POP_ID=$(curl -s --write-out "%{http_code}\n" --location --request PUT "$API_LOCATION/environments/$ENV_ID/populations/$EMPLOYEE_POP_ID" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN"  --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
        --header 'Content-Type: application/json' \
        --data-raw '{
            "name" : "More Sample Users",
            "description" : "This is a sample population."
        }')

        # check response code
        UPDATE_EMPLOYEE_POP_ID_RESULT=$(echo $UPDATE_EMPLOYEE_POP_ID | sed 's@.*}@@' )
        if [ "$UPDATE_EMPLOYEE_POP_ID_RESULT" == "200" ] ; then

            # check for new population name
            MORE_SAMPLE_USERS_POP_NAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
            --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="More Sample Users") | .name')

            # check if new sample population matches expected name, verifying sucessful update
            if [ "$MORE_SAMPLE_USERS_POP_NAME" == "More Sample Users" ]; then
                echo "Employee population successfully reverted to More Sample Users population..."
            else
                echo "Employee population successfully reverted to More Sample Users population, however unable to verify new name change!"
            fi
        fi
    else
        echo "Contractor population or Employee population not found. Exiting..."
        exit 0
    fi
done
echo "Revert User Populations checks and tasks completed."