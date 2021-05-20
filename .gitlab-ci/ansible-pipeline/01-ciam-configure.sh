#!/bin/sh

export ENV_ID="$CIAM_ENV_ID"
export PLAYBOOK='p1_pf_playbook.yml'
sh /ansible/entrypoint.sh