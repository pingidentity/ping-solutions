#!/bin/bash

# revert example themes in PingOne from CIAM

#Variables needed to be passed for this script:
#API_LOCATION
#ENV_ID
#WORKER_APP_ACCESS_TOKEN

SPLIT_THEME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/themes" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.themes[] | select(.template=="split") | .configuration.name')

MURAL_THEME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/themes" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.themes[] | select(.template=="mural") | .configuration.name')

SLATE_THEME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/themes" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.themes[] | select(.template=="slate") | .configuration.name')

FOCUS_THEME=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/themes" \
--header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.themes[] | select(.template=="focus") | .configuration.name')

THEMES[0]="$SPLIT_THEME"
THEMES[1]="$MURAL_THEME"
THEMES[2]="$SLATE_THEME"
THEMES[3]="$FOCUS_THEME"

# check for matching theme names
for THEME in "${THEMES[@]}"; do
    if [[ "$THEME" == "Ping Split" ]] || [[ "$THEME" == "Ping Mural" ]] || [[ "$THEME" == "Ping Slate" ]] || [[ "$THEME" == "Ping Focus" ]] ; then

        # get ID of expected matching theme name
        if [ "$THEME" == "Ping Split" ]; then
            THEME_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/themes" \
            --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.themes[] | select(.template=="split") , select(.name=="'"$THEME"'") | .id')
        elif [ "$THEME" == "Ping Mural" ]; then
            THEME_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/themes" \
            --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.themes[] | select(.template=="mural") , select(.name=="'"$THEME"'") | .id')
        elif [ "$THEME" == "Ping Slate" ]; then
            THEME_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/themes" \
            --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.themes[] | select(.template=="slate") , select(.name=="'"$THEME"'") | .id')
        elif [ "$THEME" == "Ping Focus" ]; then
            THEME_ID=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/themes" \
            --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.themes[] | select(.template=="focus") , select(.name=="'"$THEME"'") | .id')
        fi

        # delete matching app using ID
        DELETE_THEME=$(curl -s --write-out "%{http_code}\n" --location --request DELETE "$API_LOCATION/environments/$ENV_ID/themes/$THEME_ID" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN")

        # verify app deletion
        DELETE_THEME_RESULT=$(echo $DELETE_THEME | sed 's@.*}@@')
        if [ "$DELETE_THEME_RESULT" == "204" ]; then
            echo "$THEME theme removed successfully..."
        else
            echo "$THEME theme was not removed!"
            exit 1
        fi
    fi
done