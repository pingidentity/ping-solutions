#!/bin/sh

export ENV_ID="$CIAM_ENV_ID"
export PINGFED_BASE_URL="$CIAM_PINGFED_BASE_URL"
# -vvv in below is to trick very very verbose without modifying image.
sh /ansible/entrypoint.sh
