#!/bin/sh

export ENV_ID="$CIAM_ENV_ID"
# -vvv in below is to trick very very verbose without modifying image.
export PLAYBOOK='p1_pf_playbook.yml -vvv'
sh /ansible/entrypoint.sh
