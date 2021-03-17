#!/bin/bash

# configure example themes in PingOne for CIAM

#Variables needed to be passed for this script:
# API_LOCATION
# ENV_ID
# WORKER_APP_ACCESS_TOKEN

echo "------ Beginning 500-branding_theme_set.sh ------"

api_call_retry_limit=2

create_focus_ct=0
create_slate_ct=0
create_mural_ct=0
create_split_ct=0

function create_focus() {
    # create Ping Focus theme
    CREATE_FOCUS_THEME=$(curl -s --write-out "%{http_code}\n" --location --request POST "$API_LOCATION/environments/$ENV_ID/themes" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "template": "focus",
        "configuration": {
            "logoType": "IMAGE",
            "logo": {
                "href": "https://d3uinntk0mqu3p.cloudfront.net/branding/market/a3d073bc-3108-49ad-b96c-404bea59a1d0.png",
                "id": "00000000-0000-0000-0000-000000000000"
            },
            "backgroundColor": "#ededed",
            "backgroundType": "COLOR",
            "bodyTextColor": "#4a4a4a",
            "cardColor": "#fcfcfc",
            "headingTextColor": "#cb0020",
            "linkTextColor": "#2996cc",
            "buttonColor": "#cb0020",
            "buttonTextColor": "#ffffff",
            "name": "Ping Focus",
            "footer": "Experience sweet, secure digital experiences."
        }
    }')

    create_focus_ct=$((create_focus_ct+1))

    # checks theme created, as well as verify expected theme name to ensure creation
    CREATE_FOCUS_THEME_RESULT=$(echo $CREATE_FOCUS_THEME | sed 's@.*}@@')
    if [ $CREATE_FOCUS_THEME_RESULT == "200" ] ; then

        CHECK_FOCUS_THEME_CONTENT=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/themes" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.themes[] | select(.template=="focus") | .configuration.name')

        if [ "$CHECK_FOCUS_THEME_CONTENT" == "Ping Focus" ]; then
            echo "Ping Focus theme added and verified content..."
        else
            echo "Ping Focus theme added, however unable to verified content!"
        fi
    #if we're under the limit and it wasn't successful, retry.
    elif [[ "$CREATE_FOCUS_THEME_RESULT" != "200" ]] && [[ "$create_focus_ct" -lt "$api_call_retry_limit" ]]; then
        #rerun this
        create_focus
    else
        echo "Ping Focus theme NOT added!"
        exit 1
    fi
}

function create_slate() {
    # create Ping Slate theme
    CREATE_SLATE_THEME=$(curl -s --write-out "%{http_code}\n" --location --request POST "$API_LOCATION/environments/$ENV_ID/themes" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "template": "slate",
        "configuration": {
            "logoType": "IMAGE",
            "logo": {
                "href": "https://d3uinntk0mqu3p.cloudfront.net/branding/market/a3d073bc-3108-49ad-b96c-404bea59a1d0.png",
                "id": "00000000-0000-0000-0000-000000000000"
            },
            "backgroundColor": "",
            "backgroundType": "DEFAULT",
            "bodyTextColor": "#4C4C4C",
            "cardColor": "#FFFFFF",
            "headingTextColor": "#4A4A4A",
            "linkTextColor": "#5F5F5F",
            "buttonColor": "#4A4A4A",
            "buttonTextColor": "#FFFFFF",
            "name": "Ping Slate",
            "footer": "Experience sweet, secure digital experiences."
        }
    }')

    create_slate_ct=$((create_slate_ct+1))

    # checks theme created, as well as verify expected theme name to ensure creation
    CREATE_SLATE_THEME_RESULT=$(echo $CREATE_SLATE_THEME | sed 's@.*}@@')
    if [ $CREATE_SLATE_THEME_RESULT == "200" ] ; then

        CHECK_SLATE_THEME_CONTENT=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/themes" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.themes[] | select(.template=="slate") | .configuration.name')

        if [ "$CHECK_SLATE_THEME_CONTENT" == "Ping Slate" ]; then
            echo "Ping Slate theme added and verified content..."
        else
            echo "Ping Slate theme added, however unable to verified content!"
        fi
    #if we're under the limit and it wasn't successful, retry.
    elif [[ "$CREATE_SLATE_THEME_RESULT" != "200" ]] && [[ "$create_slate_ct" -lt "$api_call_retry_limit" ]]; then
        create_slate
    else
        echo "Ping Slate theme NOT added!"
        exit 1
    fi
}

function create_mural() {
    # create Ping Mural theme
    CREATE_MURAL_THEME=$(curl -s --write-out "%{http_code}\n" --location --request POST "$API_LOCATION/environments/$ENV_ID/themes" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "template": "mural",
        "configuration": {
            "logoType": "IMAGE",
            "logo": {
                "href": "https://d3uinntk0mqu3p.cloudfront.net/branding/market/a3d073bc-3108-49ad-b96c-404bea59a1d0.png",
                "id": "00000000-0000-0000-0000-000000000000"
            },
            "backgroundColor": "",
            "backgroundType": "DEFAULT",
            "bodyTextColor": "#000000",
            "cardColor": "#fcfcfc",
            "headingTextColor": "#000000",
            "linkTextColor": "#2996cc",
            "buttonColor": "#61b375",
            "buttonTextColor": "#ffffff",
            "name": "Ping Mural",
            "footer": "Experience sweet, secure digital experiences."
        }
    }')

    create_mural_ct=$((create_mural_ct+1))

    # checks theme created, as well as verify expected theme name to ensure creation
    CREATE_MURAL_THEME_RESULT=$(echo $CREATE_MURAL_THEME | sed 's@.*}@@')
    if [ $CREATE_MURAL_THEME_RESULT == "200" ] ; then

        CHECK_MURAL_THEME_CONTENT=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/themes" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.themes[] | select(.template=="mural") | .configuration.name')

        if [ "$CHECK_MURAL_THEME_CONTENT" == "Ping Mural" ]; then
            echo "Ping Mural theme added and verified content..."
        else
            echo "Ping Mural theme added, however unable to verified content!"
        fi
    #if we're under the limit and it wasn't successful, retry.
    elif [[ "$CREATE_MURAL_THEME_RESULT" != "200" ]] && [[ "$create_mural_ct" -lt "$api_call_retry_limit" ]]; then
        create_mural
    else
        echo "Ping Mural theme NOT added!"
        exit 1
    fi
}

function create_split() {
    # create Ping Split theme
    CREATE_SPLIT_THEME=$(curl -s --write-out "%{http_code}\n" --location --request POST "$API_LOCATION/environments/$ENV_ID/themes" \
    --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "template": "split",
        "configuration": {
            "logoType": "IMAGE",
            "logo": {
                "href": "https://d3uinntk0mqu3p.cloudfront.net/branding/market/a3d073bc-3108-49ad-b96c-404bea59a1d0.png",
                "id": "00000000-0000-0000-0000-000000000000"
            },
            "backgroundColor": "#263956",
            "backgroundType": "COLOR",
            "bodyTextColor": "#263956",
            "cardColor": "#fcfcfc",
            "headingTextColor": "#686f77",
            "linkTextColor": "#263956",
            "buttonColor": "#263956",
            "buttonTextColor": "#ffffff",
            "name": "Ping Split",
            "footer": "Experience sweet, secure digital experiences."
        }
    }')

    create_split_ct=$((create_split_ct+1))

    # checks theme created, as well as verify expected theme name to ensure creation
    CREATE_SPLIT_THEME_RESULT=$(echo $CREATE_SPLIT_THEME | sed 's@.*}@@')
    if [ $CREATE_SPLIT_THEME_RESULT == "200" ] ; then

        CHECK_SPLIT_THEME_CONTENT=$(curl -s --location --request GET "$API_LOCATION/environments/$ENV_ID/themes" \
        --header "Authorization: Bearer $WORKER_APP_ACCESS_TOKEN" | jq -rc '._embedded.themes[] | select(.template=="split") | .configuration.name')

        if [ "$CHECK_SPLIT_THEME_CONTENT" == "Ping Split" ]; then
            echo "Ping Split theme added and verified content..."
        else
            echo "Ping Split theme added, however unable to verified content!"
        fi
    #if we're under the limit and it wasn't successful, retry.
    elif [[ "$CREATE_SPLIT_THEME_RESULT" != "200" ]] && [[ "$create_split_ct" -lt "$api_call_retry_limit" ]]; then
        create_split
    else
        echo "Ping Split theme NOT added!"
        exit 1
    fi
}

#call the functions above.
create_focus
create_slate
create_mural
create_split

echo "------ End 500-branding_theme_set.sh ------"