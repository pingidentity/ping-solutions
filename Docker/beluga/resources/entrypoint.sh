
#!/bin/sh
if [[ -z ${TOKEN_ENDPOINT+x} ]] && [[ -n ${CLIENT_ID+x} ]] && [[ -n ${CLIENT_SECRET+x} ]]; then
    echo "Necessary variables not set, exiting..."
    exit 0
else
    echo "Necessary variables set, continuing..."
fi

P1_VAR_FILE="/ansible/playbooks/p1_vars.json"
PF_VAR_FILE="/ansible/playbooks/pf_vars.json"
ENV_METADATA_JSON_FILE="/ansible/playbooks/env_metadata.json"

#Set required variables from ENVIRONMENT_METADATA_JSON
ENV_ID=$(echo $ENVIRONMENT_METADATA_JSON | jq -rc '.pingOneInformation.environmentId')
export API_LOCATION=$( echo $ENVIRONMENT_METADATA_JSON | jq -rc '.pingOneInformation.webhookBaseUrl + "/v1"')
export ORG_ID=$( echo $ENVIRONMENT_METADATA_JSON | jq -rc '.pingOneInformation.organizationId')
export AUTH_TOKEN_ENDPOINT=$(echo "$TOKEN_ENDPOINT/token.oauth2")

#check PINGFED url format
if [[ "$PINGFEDERATE_ADMIN_SERVER" == https://* ]];then
    echo "PF Admin Server includes https:// prefix."
else
    echo "PF Admin Server url does not include https:// prefix, adding for Ansible."
    PINGFEDERATE_ADMIN_SERVER=$(echo 'https://'"$PINGFEDERATE_ADMIN_SERVER")
fi

#generate the PF base url
if [ -n $PF_ADMIN_PORT ]; then
    export PINGFED_BASE_URL=$(echo "$PINGFEDERATE_ADMIN_SERVER:$PF_ADMIN_PORT")
else
    export PINGFED_BASE_URL=$(echo "$PINGFEDERATE_ADMIN_SERVER")
fi


#create flat file to use in Ansible to define various P1 variables. Will move existing to old if script has already run against target environment
if [[ -n "$AUTH_TOKEN_ENDPOINT" ]] && [[ -n "$CLIENT_ID" ]] && [[ -n "$CLIENT_SECRET" ]]; then
    if [ -f "$P1_VAR_FILE" ]; then
        echo "Existing vars.json file present, taking care of that..."
        mv "$P1_VAR_FILE" "$P1_VAR_FILE.old"
        echo "" > "$P1_VAR_FILE.old"
        touch "$P1_VAR_FILE"
        jq -n --arg'{ENV_ID: env.ENV_ID, API_LOCATION: env.API_LOCATION, ORG_ID: env.ORG_ID, TOKEN_ENDPOINT: env.AUTH_TOKEN_ENDPOINT, CLIENT_ID: env.CLIENT_ID, CLIENT_SECRET: env.CLIENT_SECRET }' > "$P1_VAR_FILE"
    else
        echo "Creating vars.json..."
        touch "$P1_VAR_FILE"
                jq -n '{ENV_ID: env.ENV_ID, API_LOCATION: env.API_LOCATION, ORG_ID: env.ORG_ID, TOKEN_ENDPOINT: env.AUTH_TOKEN_ENDPOINT, CLIENT_ID: env.CLIENT_ID, CLIENT_SECRET: env.CLIENT_SECRET }' > "$P1_VAR_FILE"
    fi
else
    echo "TOKEN_ENDPOINT, ENV_ID, CLIENT_ID, API_LOCATION, ORG_ID, CLIENT_SECRET variable(s) not present, exiting..."
    exit 1
fi

#create flat file to use in Ansible to define various PF variables. Will move existing to old if script has already run against target environment
if [[ -n "$PINGFEDERATE_ADMIN_SERVER" ]] && [[ -n "$PF_USERNAME" ]] && [[ -n "$PF_PASSWORD" ]] && [[ -n "$PF_ADMIN_PORT" ]]; then
    if [ -f "$PF_VAR_FILE" ]; then
        echo "Existing pf_vars.json file present, taking care of that..."
        mv "$PF_VAR_FILE" "$PF_VAR_FILE.old"
        echo "" > "$PF_VAR_FILE.old"
        touch "$PF_VAR_FILE"
        jq -n '{PINGFEDERATE_ADMIN_SERVER: env.PINGFEDERATE_ADMIN_SERVER, PF_USERNAME: env.PF_USERNAME, PF_PASSWORD: env.PF_PASSWORD, PF_ADMIN_PORT: env.PF_ADMIN_PORT, PINGFED_BASE_URL: env.PINGFED_BASE_URL }' > "$PF_VAR_FILE"

        #setting explicit due to WF/CIAM in pipeline
    else
        echo "Creating pf_vars.json..."
        touch "$PF_VAR_FILE"
jq -n '{PINGFEDERATE_ADMIN_SERVER: env.PINGFEDERATE_ADMIN_SERVER, PF_USERNAME: env.PF_USERNAME, PF_PASSWORD: env.PF_PASSWORD, PF_ADMIN_PORT: env.PF_ADMIN_PORT, PINGFED_BASE_URL: env.PINGFED_BASE_URL }' > "$PF_VAR_FILE"
        #skipping for dev image
        #echo '"PINGFED_BASE_URL":"'"$PINGFEDERATE_ADMIN_SERVER"':'"$PF_ADMIN_PORT"'"' >> "$PF_VAR_FILE"
        #setting explicit due to WF/CIAM in pipeline
    fi
else
    echo "PINGFEDERATE_ADMIN_SERVER, PF_USERNAME, PF_PASSWORD, PF_ADMIN_PORT variable(s) not present, exiting..."
    exit 1
fi

if [ -n "$ENVIRONMENT_METADATA_JSON" ]; then
    if [ -f "$ENV_METADATA_JSON_FILE" ]; then
        echo "Existing env_metadata.json file present, taking care of that..."
        mv $ENV_METADATA_JSON_FILE "$ENV_METADATA_JSON_FILE.old"
        echo "" > "$ENV_METADATA_JSON_FILE.old"
        touch $ENV_METADATA_JSON_FILE
        echo "$ENVIRONMENT_METADATA_JSON" >> $ENV_METADATA_JSON_FILE
    else
        echo "Creating env_metadata.json file..."
        touch $ENV_METADATA_JSON_FILE
        echo "$ENVIRONMENT_METADATA_JSON" >> $ENV_METADATA_JSON_FILE
    fi
else
    echo "ENVIRONMENT_METADATA_JSON variable not present, exiting..."
    exit 1
fi

#run the playbook
ansible-playbook \
--extra-vars @"$P1_VAR_FILE" \
--extra-vars @"$PF_VAR_FILE" \
--extra-vars @"$ENV_METADATA_JSON_FILE" \
/ansible/playbooks/p1_pf_playbook.yml