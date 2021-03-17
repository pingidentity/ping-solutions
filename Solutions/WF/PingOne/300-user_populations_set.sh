#!/bin/bash

# renames Sample Populations to WF use case examples

#Variables needed to be passed for this script:
# API_LOCATION
# ENV_ID
# WORKER_APP_ACCESS_TOKEN

echo "------ Beginning 300-user_populations_set.sh ------"

# set global api call retry limit - this can be set to desired amount, default is 2
api_call_retry_limit=2

#cheating with user pop set because I was lazy with the function. Wanna give it the legit number of tries since the incremement is at the start.
user_pop_set=-1
user_pop_get=0
sample_set=0
more_sample_set=0


function get_user_pop_id() {
    #increment
    user_pop_get=$((user_pop_get+1))
    # get Sample Users population name
    SAMPLE_USERS_POP=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Sample Users") | .name')
    
    # get More Sample Users population name
    MORE_SAMPLE_USERS_POP=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="More Sample Users") | .name')
    
   

    #if all right set variables and move on.
    if [[ $SAMPLE_USERS_POP == "Sample Users" ]] && [[ $MORE_SAMPLE_USERS_POP == "More Sample Users" ]]; then
        echo "User populations found successfully."
        SAMPLE_POPS[0]="$SAMPLE_USERS_POP"
        SAMPLE_POPS[1]="$MORE_SAMPLE_USERS_POP"
        #call the next function to do the work
        set_user_pop
    #if either isn't set and limit is below number of runtimes       
    elif ([[ $SAMPLE_USERS_POP != "Sample Users" ]] || [[ $MORE_SAMPLE_USERS_POP != "More Sample Users" ]]) && [[ "$user_pop_set" -lt "$api_call_retry_limit" ]]; then
        echo "Sample Users population or More Sample Users population not found. Retrying."
        get_user_pop_id
    #out of tries and one or both not set
    elif ([[ $SAMPLE_USERS_POP != "Sample Users" ]] || [[ $MORE_SAMPLE_USERS_POP != "More Sample Users" ]]) && [[ "$user_pop_set" -ge "$api_call_retry_limit" ]]; then
        echo "One or both population(s) not found and number of allowed runs exceeded, exiting now."
        exit 1
    fi
}


function set_user_pop() {
    #increment
    user_pop_set=$((user_pop_set+1))
    for SAMPLE_POP in "${SAMPLE_POPS[@]}"; do

        # check if name matches Sample Users population
        if [ "$SAMPLE_POP" == "Sample Users" ]; then
        sample_set=$((sample_set+1))

            # get sample users population ID
            SAMPLE_USERS_POP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
            --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Sample Users") | .id')

            if [[ -n "$SAMPLE_USERS_POP_ID" ]] && [[ $SAMPLE_USERS_POP_ID != 'null' ]] && [[ "$sample_set" -lt "$api_call_retry_limit" ]]; then
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
                        echo "Sample Users population successfully updated to Contractors..."
                    else
                        echo "Sample Users population updated, however unable to verify new name change!"
                    fi
                fi
            #if unset or null, rerun if within limit
            elif ([ -z ${SAMPLE_USERS_POP_ID+x} ] || [[ "$SAMPLE_USERS_POP_ID" == 'null' ]]) \
            && [[ "$sample_set" -lt "$api_call_retry_limit" ]] && [[ "$User_pop_set" -lt "$api_call_retry_limit" ]]; then
                #retry!
                set_user_pop
            #if unset, too many runs, or other problem we're quitting now.
            else
                echo "Sample Users population not found and number of allowed runs exceeded, exiting now."
                exit 1
            fi    


        # check if name matches More Sample Users population
        elif [ "$SAMPLE_POP" == "More Sample Users" ]; then
        more_sample_set=$((more_sample_set+1))

            # get more sample users population ID
            MORE_SAMPLE_USERS_POP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/populations" \
            --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="More Sample Users") | .id')

            if [[ -n "$MORE_SAMPLE_USERS_POP_ID" ]] && [[ $MORE_SAMPLE_USERS_POP_ID != 'null' ]] && [[ "$sample_set" -lt "$api_call_retry_limit" ]]; then
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
            #if unset or null, rerun if within limit
            elif ([ -z ${MORE_SAMPLE_USERS_POP_NAME+x} ] || [[ "$MORE_SAMPLE_USERS_POP_NAME" == 'null' ]]) \
            && [[ "$more_sample_set" -lt "$api_call_retry_limit" ]] && [[ "$User_pop_set" -lt "$api_call_retry_limit" ]]; then
                #retry!
                set_user_pop
            #if unset, too many runs, or other problem we're quitting now.
            else
                echo "More Sample Users population not found and number of allowed runs exceeded, exiting now."
                exit 1
            fi    
        else
            echo "Sample Users population or More Sample Users population not found. Exiting..."
            exit 1
        fi
    done
}

#start all of this logic
get_user_pop_id

echo "Set User Populations checks and tasks completed."

echo "------ End of 300-user_populations_set.sh ------"