#!/bin/bash
# Script to verify features and types

echo "Performing PingOne configuration revertion"

#performing final PingOne revertion/deletion scripts
for script in ../Solutions/WF/$CURRENT_PIPELINE_VERSION/PingOne/*revert.sh; do
  echo "Executing $script..."
  bash $script 
done

