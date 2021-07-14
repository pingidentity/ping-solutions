#!/bin/bash

# runs Solutions pre-configs

# Variables needed to run script
# API_LOCATION
# ENV_ID
# WORKER_APP_ACCESS_TOKEN
# PF_USERNAME
# PF_PASSWORD
# PINGFED_BASE_URL
# AUTH_SERVER_BASE_URL

function pingfederate() {
    #define script for job.

    # set global api call retry limit - this can be set to desired amount, default is 1
    api_call_retry_limit=1

    echo "------ Beginning PingFederate Admin SSO ------"

    #################################### get administrator env ####################################
    admin_env_try=0

    function get_admin_env() {
        # checks org is present
        if [[ "$ORG_ID" =~ ^\{?[A-F0-9a-f]{8}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{12}\}?$ ]] && [[ "$admin_env_try" < "$api_call_retry_limit" ]] ; then
            echo "Org info available, getting ID..."
            # set administrators environment name
            ADMIN_ENV_NM='Administrators'
            # get env id
            ADMIN_ENV_ID=$(curl -s --location --request GET "$ORG_HREF/environments/" \
            --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | \
            jq -rc '._embedded.environments[] | select(.name=="'"$ADMIN_ENV_NM"'") | .id')
            if [[ -z "$ADMIN_ENV_ID" ]] || [[ "$ADMIN_ENV_ID" == "" ]]; then
                echo "Unable to get ADMIN ENV ID, retrying..."
                admin_env_try=$((admin_env_try+1))
                check_admin_env
            else
                AS_ENDPOINT=$(echo "$AUTH_SERVER_BASE_URL/$ADMIN_ENV_ID/as")
                echo "ADMIN ENV ID set, proceeding..."
            fi
        else
            echo "Unable to successfully retrieve Admin ENV ID and exceeded try limit!"
            exit 1
        fi
    }

    function check_admin_env() {
        ENV_GET=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN")

        ORG_ID=$(echo "$ENV_GET" | jq -rc '.organization.id')
        ORG_HREF=$(echo "$ENV_GET" | jq -rc '._links.organization.href')

        get_admin_env
    }
    check_admin_env

    #################################### finish get admin env ####################################

    #################################### check administrator schema ####################################
    user_schema_try=0

    function assign_schema_id() {
        # checks schema is present
        USER_SCHEMA_RESULT=$(echo $USER_SCHEMA | sed 's@.*}@@')
        if [[ "$USER_SCHEMA_RESULT" == "200" ]] && [[ "$user_schema_try" < "$api_call_retry_limit" ]] ; then
            echo "Schema available, getting ID..."
            # get signing cert id
            USER_SCHEMA_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ADMIN_ENV_ID/schemas" \
            --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.schemas[].id')
            if [[ -z "$USER_SCHEMA_ID" ]] || [[ "$USER_SCHEMA_ID" == "" ]]; then
                echo "Unable to get schema ID, retrying..."
                check_schema
            else
                echo "Schema ID set, proceeding..."
            fi
        elif [[ $SIGNING_CERT_KEYS_RESULT != "200" ]] && [[ "$user_schema_try" < "$api_call_retry_limit" ]]; then
            user_schema_tries=$((api_call_retry_limit-user_schema_try))
            echo "Unable to retrieve schema! Retrying $user_schema_tries..."
            user_schema_try=$((user_schema_try+1))
            check_schema
        else
            echo "Unable to successfully retrieve schema and exceeded try limit!"
            exit 1
        fi
    }

    function check_schema() {
        USER_SCHEMA=$(curl -s --write-out "%{http_code}\n" --location --request GET "$API_LOCATION/environments/$ADMIN_ENV_ID/schemas" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN")
        assign_schema_id
    }
    check_schema

    #################################### check, create, or set administrator population ####################################
    admin_pop_try=0

    function check_admin_pop_content() {
        # verify name again
        ADMIN_POP_NAME_AGAIN=$(curl -s --location --request GET "$API_LOCATION/environments/$ADMIN_ENV_ID/populations" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Administrators Population") | .name')
        if [ "$ADMIN_POP_NAME_AGAIN" == "Administrators Population" ]; then
            echo "Administrators Population verified, setting population ID..."
            ADMIN_POP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ADMIN_ENV_ID/populations" \
            --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Administrators Population") | .id')
            if [[ -z "$ADMIN_POP_ID" ]] || [[ "$ADMIN_POP_ID" == "" ]]; then
                echo "Administrator Population ID unable to be set correctly, retrying..."
                check_admin_pop_content
            else
                echo "Administrators Population ID set correctly..."
            fi
        else
            admin_pop_tries_left=$((api_call_retry_limit-admin_pop_try))
            echo "Unable to verify Administrators population. Retrying $admin_pop_tries_left..."
            admin_pop_try=$((admin_pop_try+1))
            check_admin_pop
        fi
    }

    function check_admin_pop() {
        # check name for existence
        ADMIN_POP_NAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ADMIN_ENV_ID/populations" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.populations[] | select(.name=="Administrators Population") | .name')
        if [ "$ADMIN_POP_NAME" != "Administrators Population" ]; then
            echo "Administrators Population does not exist, adding..."
            # create administrators population
            CREATE_ADMIN_POP=$(curl -s --write-out "%{http_code}\n" --location --request POST "$API_LOCATION/environments/$ADMIN_ENV_ID/populations" \
            --header 'content-type: application/json' \
            --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
            --data-raw '{
            "name" : "Administrators Population",
            "description" : "Administrators Population"
            }')

            CREATE_ADMIN_POP_RESULT=$(echo $CREATE_ADMIN_POP | sed 's@.*}@@')
            if [[ $CREATE_ADMIN_POP_RESULT == "201" ]]; then
                echo "Administrators Population added, beginning content check..."
                check_admin_pop_content
            elif [[ $CREATE_ADMIN_POP_RESULT != "201" ]] && [[ "$admin_pop_try" < "$api_call_retry_limit" ]]; then
                echo "Administrators Population NOT added! Checking population existence..."
                check_admin_pop_content
            else
                echo "Administrators Population NOT added and attempts to create exceeded!"
                exit 1
            fi

        else
            echo "Administrators Population found, verifying..."
            check_admin_pop_content
        fi
    }
    check_admin_pop

    # #################################### Create PFAdmin Group ##################
    admin_group_try=0

    function check_admin_group_content() {
        CHECK_PF_ADMIN_GROUP_AGAIN=$(curl -s --location --request GET "$API_LOCATION/environments/$ADMIN_ENV_ID/groups?filter=name%20eq%20%22PingFederate%20Administrators%22&limit=20" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
        | jq -rc '._embedded.groups[] | select (.name=="PingFederate Administrators") | .name')
        if [ "$CHECK_PF_ADMIN_GROUP_AGAIN" != "PingFederate Administrators" ] && [[ "$admin_group_try" < "$api_call_retry_limit" ]]; then
            admin_group_tries_left=$((api_call_retry_limit-admin_group_try))
            echo "Unable to verify content... Retrying $admin_group_tries_left more time(s)..."
            admin_group_try=$((admin_group_try+1))
            create_admin_group
        else
            echo "PingFederate Administrators group exists and verified content, setting ID variable..."
            PF_ADMIN_GROUP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ADMIN_ENV_ID/groups?filter=name%20eq%20%22PingFederate%20Administrators%22&limit=20" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
            | jq -rc '._embedded.groups[] | select (.name=="PingFederate Administrators") | .id')

            if [ -z ${PF_ADMIN_GROUP_ID+x} ]; then
                echo "Unable to set PingFederate Administrators group ID, retrying..."
                check_admin_group_content
            else
                echo "PingFederate Administrators group ID set correctly..."
            fi
        fi
    }

    function create_admin_group() {
        # check if admin group already exists
        CHECK_PF_ADMIN_GROUP=$(curl -s --location --request GET "$API_LOCATION/environments/$ADMIN_ENV_ID/groups?filter=name%20eq%20%22PingFederate%20Administrators%22&limit=20" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
        | jq -rc '._embedded.groups[] | select (.name=="PingFederate Administrators") | .name')
        if [ "$CHECK_PF_ADMIN_GROUP" != "PingFederate Administrators" ]; then
            # create PingFed Administrators group
              CREATE_PF_ADMIN_GROUP=$(curl -s --write-out "%{http_code}\n" --location --request POST "$API_LOCATION/environments/$ADMIN_ENV_ID/groups" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
                --header 'Content-Type: application/json' \
                --data-raw '{
                    "name" : "PingFederate Administrators",
                    "description" : "User group for PingFed Admin SSO privileges.",
                    "userFilter": "population.id eq \"'"$ADMIN_POP_ID"'\""
                }')
            # checks group created, as well as verify expected group name to ensure creation
            CREATE_PF_ADMIN_GROUP_RESULT=$(echo $CREATE_PF_ADMIN_GROUP | sed 's@.*}@@')
            if [[ $CREATE_PF_ADMIN_GROUP_RESULT == "201" ]]; then
                echo "PingFederate Administrators group added, beginning content check..."
                check_admin_group_content
            elif [[ $CREATE_PF_ADMIN_GROUP_RESULT != "201" ]] && [[ "$admin_group_try" < "$api_call_retry_limit" ]]; then
                echo "PingFederate Administrators group NOT added! Checking group existence..."
                check_admin_group_content
            else
                echo "PingFederate Administrators group does NOT exist and attempts to create exceeded!"
                exit 1
            fi
        else
            echo "PingFederate Administrators group existence check passed. Checking content..."
            check_admin_group_content
        fi
    }
     create_admin_group

    #################################### export values into oidc properties tmp file ####################################

    # check for existing files
    OIDC_FILE="./oidc.properties.tmp"
    RUN_PROP_FILE="./run.properties.tmp"

    function write_oidc_file_out {

        # get, set oidc content, this is very important for creating the file later
        oauth_cons_try=0
        function oidc_content() {
            OIDC_APP_OAUTH_CONTENT_CHECK=$(curl -s --write-out "%{http_code}\n" --location --request GET "$AS_ENDPOINT/.well-known/openid-configuration")
            OIDC_APP_OAUTH_CONTENT_CHECK_RESULT=$(echo $OIDC_APP_OAUTH_CONTENT_CHECK | sed 's@.*}@@')
            if [ $OIDC_APP_OAUTH_CONTENT_CHECK_RESULT == "200" ]; then
                echo "openid configuration content found, setting to be used for other variables..."
                OIDC_APP_OAUTH_CONTENT=$(curl -s --location --request GET "$AS_ENDPOINT/.well-known/openid-configuration")
                APP_AUTH_EP=$( echo "$OIDC_APP_OAUTH_CONTENT" | jq -rc '.authorization_endpoint' )
                APP_TOKEN_EP=$( echo "$OIDC_APP_OAUTH_CONTENT" | jq -rc '.token_endpoint' )
                APP_USERINFO_EP=$( echo "$OIDC_APP_OAUTH_CONTENT" | jq -rc '.userinfo_endpoint' )
                APP_SO_EP=$( echo "$OIDC_APP_OAUTH_CONTENT" | jq -rc '.end_session_endpoint' )
                APP_ISSUER=$( echo "$OIDC_APP_OAUTH_CONTENT" | jq -rc '.issuer' )
                APP_SCOPES=$( echo "$OIDC_APP_OAUTH_CONTENT" | jq -rc '.scopes_supported' | sed -e 's/\[//g' -e 's/\"/ /g' -e 's/ //g' -e 's/\,/ /g' -e 's/\]//g')
            elif [[ $OIDC_APP_OAUTH_CONTENT_CHECK_RESULT != "200" ]] && [[ "$oauth_cons_try" < "$api_call_retry_limit" ]]; then
                oauth_cons_tries_left=$((api_call_retry_limit-oauth_cons_try))
                echo "Unable to get openid configuration content, retrying $oauth_cons_tries_left..."
                oauth_cons_try=$((oauth_cons_try+1))
                oidc_content
            else
                echo "Unable to retrieve openid configuration content and set other variables. Maximum attempts exceeded!"
                exit 1
            fi
        }
        oidc_content


        # get, set role name from PingFederateAdmin SSO app
        role_name_try=0
        function role_name() {
            APP_ROLE_NAME_CHECK=$(curl -s --write-out "%{http_code}\n" --location --request GET "$API_LOCATION/environments/$ADMIN_ENV_ID/users/$ADMIN_ACCOUNT_ID?expand=population" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN")
            APP_ROLE_NAME_CHECK_RESULT=$(echo $APP_ROLE_NAME_CHECK | sed 's@.*}@@')
            if [ $APP_ROLE_NAME_CHECK_RESULT == "200" ]; then
                echo "role name found, setting..."
                APP_ROLE_NAME=$(curl -s --location --request GET "$API_LOCATION/environments/$ADMIN_ENV_ID/users/$ADMIN_ACCOUNT_ID?expand=population" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '."pf-admin-role"')
            elif [[ $APP_ROLE_NAME_CHECK_RESULT != "200" ]] && [[ "$role_name_try" < "$api_call_retry_limit" ]]; then
                role_name_tries_left=$((api_call_retry_limit-role_name_try))
                echo "Unable to retrieve role name, retrying $role_name_tries_left..."
                role_name_try=$((role_name_try+1))
                role_name
            else
                echo "Unable to retrieve role name. Maximum attempts exceeded!"
                exit 1
            fi
        }
        role_name

        #set variable already known
        APP_AUTHN_METHOD="client_secret_basic"

    ### Output variables to OIDC properties file ###
        echo "PF_OIDC_CLIENT_AUTHN_METHOD=$APP_AUTHN_METHOD" >> $OIDC_FILE
        # the client secret maybe need to be run against obfuscate script in PingFederate
        echo "PF_OIDC_AUTHORIZATION_ENDPOINT=$APP_AUTH_EP" >> $OIDC_FILE
        echo "PF_OIDC_TOKEN_ENDPOINT=$APP_TOKEN_EP" >> $OIDC_FILE
        echo "PF_OIDC_USER_INFO_ENDPOINT=$APP_USERINFO_EP" >> $OIDC_FILE
        echo "PF_OIDC_END_SESSION_ENDPOINT=$APP_SO_EP" >> $OIDC_FILE
        echo "PF_OIDC_ISSUER=$APP_ISSUER" >> $OIDC_FILE
        echo "PF_OIDC_ACR_VALUES=" >> $OIDC_FILE
        echo "PF_OIDC_SCOPES=$APP_SCOPES" >> $OIDC_FILE
        echo "PF_OIDC_USERNAME_ATTRIBUTE_NAME=sub" >> $OIDC_FILE

        echo "PF_OIDC_ROLE_ADMIN=$PF_ADMIN_GROUP_ID" >> $OIDC_FILE
        echo "PF_OIDC_ROLE_CRYPTOMANAGER=$PF_ADMIN_GROUP_ID" >> $OIDC_FILE
        echo "PF_OIDC_ROLE_USERADMIN=$PF_ADMIN_GROUP_ID" >> $OIDC_FILE
        echo "PF_OIDC_ROLE_EXPRESSIONADMIN=eadmin" >> $OIDC_FILE
        echo "PF_OIDC_ROLE_AUDITOR=" >> $OIDC_FILE
        echo "oidc.properties.tmp file written..."
    }

    # handles existing oidc file, or creates said file
    if [ -f "$OIDC_FILE" ]; then
        echo "Existing oidc file present, taking care of that..."
        mv $OIDC_FILE "$OIDC_FILE.old"
        echo -n "" > "$OIDC_FILE.old"
        echo "Existing oidc file named to $OIDC_FILE.old"
        write_oidc_file_out
    else
        echo "No existing oidc file, creating now..."
        write_oidc_file_out
    fi

    #################################### write out run.properties.tmp file ####################################
    function write_prop_file_out {

        # export values into run properties tmp file
        function hostname() {
        if [[ -z "$PINGFED_BASE_URL" ]] || [[ "$PINGFED_BASE_URL" == "" ]]; then
            echo "PINGFED_BASE_URL variable not set! This is needed to proceed with creating the run.properties.tmp file!"
            exit 1
        else
            echo "PINGFED_BASE_URL variable value found, setting variable for run.properties.tmp file..."
            PF_ADMIN_HOSTNAME="$PINGFED_BASE_URL"
        fi
        }
        hostname

        admin_env_try=0
        function admin_env_id() {
            ADMIN_ENV_ID_CHECK=$(curl -s --write-out "%{http_code}\n" --location --request GET "$API_LOCATION/environments/$ADMIN_ENV_ID" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN")
            ADMIN_ENV_ID_CHECK_RESULT=$(echo $ADMIN_ENV_ID_CHECK | sed 's@.*}@@')
            if [ $ADMIN_ENV_ID_CHECK_RESULT == "200" ]; then
                echo "Administrators Environment Found, setting ID..."
                ADMIN_ENV_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ADMIN_ENV_ID" --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '. | select(.name="Administrators") | .id')
            elif [[ $ADMIN_ENV_ID_CHECK_RESULT != "200" ]] && [[ "$admin_env_try" < "$api_call_retry_limit" ]]; then
                admin_env_tries_left=$((api_call_retry_limit-admin_env_try))
                echo "Unable to retrieve Administrators Environment, retrying $admin_env_tries_left..."
                admin_env_try=$((admin_env_try+1))
                admin_env_id
            else
                echo "Unable to retrieve Administrators Environment ID. Maximum attempts exceeded!"
                exit 1
            fi
        }
        admin_env_id

    ### Output variables to run properties file ###
        echo "PF_ADMIN_PUBLIC_HOSTNAME=$PF_ADMIN_HOSTNAME" >> $RUN_PROP_FILE
        echo "PF_ADMIN_CONSOLE_TITLE=$OIDC_APP_NAME" >> $RUN_PROP_FILE
        echo "PF_ADMIN_CONSOLE_ENVIRONMENT=$ADMIN_ENV_ID" >> $RUN_PROP_FILE
        echo "PF_CONSOLE_AUTHENTICATION=OIDC" >> $RUN_PROP_FILE
        echo "run.properties.tmp file written..."
    }

    # handles existing properties file, or creates said file
    if [ -f "$RUN_PROP_FILE" ]; then
        echo "Existing properties file present, taking care of that..."
        mv $RUN_PROP_FILE "$RUN_PROP_FILE.old"
        echo -n "" > "$RUN_PROP_FILE.old"
        echo "Existing properties file named to $RUN_PROP_FILE.old"
        write_prop_file_out
    else
        echo "No existing properties file, creating now..."
        write_prop_file_out
    fi

    echo "------ End of PingFederate Admin SSO setup ------"

    echo "###### COMPLETED SOLUTIONS PRE-CONFIG TASKS ######"
}

function check_bom() {
    BOM=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/billOfMaterials" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '.products[].type')
    BOM_RESULT=$( echo "$BOM" | sed -e 's/ //g')
    if [[ "$BOM_RESULT" == *"PING_FEDERATE"* ]]; then
        echo "Found PingFederate in Bill of Materials."
        echo "###### Executing PingFederate pre-config tasks ######"
        #actually make the worker app
        pingfederate
    else
        echo "PingFederate not found in the Bill of Materials..."
        exit 0
    fi
}

check_bom
