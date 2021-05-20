#!/bin/sh

export ENV_ID="$WF_ENV_ID"
export PINGFED_BASE_URL="$WF_PINGFED_BASE_URL"
export PLAYBOOK='pf_post_playbook.yml'
sh /ansible/entrypoint.sh