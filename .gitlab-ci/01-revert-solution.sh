#!/bin/bash
# Script to verify features and types

echo "Performing PingOne configuration revertion"
echo "Environment ID is $ENV_ID"
echo "API URL path is $API_LOCATIONS"
echo "Current pipeline version is $CURRENT_PIPELINE_VERSION"
echo "Current Org ID is $ORG_ID"


#performing final PingOne revertion/deletion scripts
for script in ./Solutions/WF/$CURRENT_PIPELINE_VERSION/PingOne/*revert.sh; do
  echo "Executing $script..."
  bash $script 
done

