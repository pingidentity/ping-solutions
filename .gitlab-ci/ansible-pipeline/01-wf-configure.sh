#!/bin/sh

export ENV_ID="$WF_ENV_ID"
export PLAYBOOK='p1_pf_playbook.yml'
sh /ansible/entrypoint.sh