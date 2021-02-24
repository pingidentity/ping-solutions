#!/bin/bash

# revert PingOne Sample SAML Apps for CIAM

#Variables needed to be passed for this script:
API_LOCATION="https://api.pingone.com/v1"
ENV_ID="ae276c77-af5c-4ae5-a82d-be219cf1b6ea"
WORKER_APP_ACCESS_TOKEN="eyJhbGciOiJSUzI1NiIsImtpZCI6ImRlZmF1bHQifQ.eyJjbGllbnRfaWQiOiJhNjlhNTY5Yy03YjI4LTQwMmItOGUyOC00NTBmOTAzYTVjZWYiLCJpc3MiOiJodHRwczovL2F1dGgucGluZ29uZS5jb20vYWUyNzZjNzctYWY1Yy00YWU1LWE4MmQtYmUyMTljZjFiNmVhL2FzIiwiaWF0IjoxNjE0MTg2MTEyLCJleHAiOjE2MTQxODk3MTIsImF1ZCI6WyJodHRwczovL2FwaS5waW5nb25lLmNvbSJdLCJlbnYiOiJhZTI3NmM3Ny1hZjVjLTRhZTUtYTgyZC1iZTIxOWNmMWI2ZWEiLCJvcmciOiIyMDQ4YjAxZC0xMjFlLTRiZWEtODc1MC1kMzNkZTY4ZmQ2ZGUifQ.N6vrcowyunQbv1_QZ-uCpegFBFfNgqsKcD5jIdfyVcyQGGJida09tQhfMZZLkI3CZ0AyxqSlN400vT8Ez8L2IHRBBAgN6ags2fL7g_w_wDSVURdyJhOpex64zd0CqsBORl5dJgT21ihRFsyLeIhxT3w2F-toWaoqB24vBBbgwF5DqiVcMibZrbmHPoefpYMDkiB-prM-g8lFVgHVh9dmBoKeAKh1EKdZFF-meInNll30nHm2fH_-8C5KYftsYpmXd0voib-UdXFfA1R4GnKZSShECQ-WYq_3TEZjUN0yDmmjw2sKBTPzAwYvDX6Dbw5SgjOg_b8ZAAGGm4XfuwCVvQ"

SAMPLE_APP_1=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select(.name=="Demo App - Self-Service Registration") | .name')

SAMPLE_APP_2=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select(.name=="Demo App - Passwordless Login SMS Only") | .name')

SAMPLE_APP_3=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select(.name=="Demo App - Passwordless Login Any Method") | .name')

SAMPLE_APPS[0]="$SAMPLE_APP_1"
SAMPLE_APPS[1]="$SAMPLE_APP_2"
SAMPLE_APPS[2]="$SAMPLE_APP_3"

for SAMPLE_APP in "${SAMPLE_APPS[@]}"; do
    if [[ "$SAMPLE_APP" == "Demo App - Self-Service Registration" ]] || [[ "$SAMPLE_APP" == "Demo App - Passwordless Login SMS Only" ]] || [[ "$SAMPLE_APP" == "Demo App - Passwordless Login Any Method" ]]; then

        # get ID of expected matching app name
        SAMPLE_APP_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/applications" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.applications[] | select(.name=="'"$SAMPLE_APP"'") | .id')

        # delete matching app using ID
        DELETE_SAMPLE_SAML_APP=$(curl -s --write-out "%{http_code}\n" --location --request DELETE "$API_LOCATION/environments/$ENV_ID/applications/$SAMPLE_APP_ID" \
        --header 'Content-Type: application/json' --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" --data-raw '')

        # verify app deletion
        DELETE_SAMPLE_SAML_APP_RESULT=$(echo $DELETE_SAMPLE_SAML_APP | sed 's@.*}@@')
        if [ "$DELETE_SAMPLE_SAML_APP_RESULT" == "204" ]; then
            echo "$SAMPLE_APP removed successfully..."
        else
            echo "$SAMPLE_APP was not removed!"
            exit 1
        fi
    else
        echo "Sample Application did not match app name expected for deletion, ignoring..."
    fi
done