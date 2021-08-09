#!/bin/sh

export ENV_ID="$WF_ENV_ID"
export PINGFED_BASE_URL="$WF_PINGFED_BASE_URL"
export PINGFEDERATE_ADMIN_SERVER="$WF_PINGFED_BASE_URL"
# -vvv in below is to trick very very verbose without modifying image.
echo "Environment ID for CIAM is $ENV_ID"
echo "PingFed base url is $PINGFED_BASE_URL"
echo "PingFederate Admin Server is $PINGFEDERATE_ADMIN_SERVER"

sh /ansible/entrypoint.sh
