#!/bin/bash
echo "Environment ID is $ENV_ID"
echo "API Location is $API_LOCATION"
echo "Worker app access token is $WORKER_APP_ACCESS_TOKEN"
bash ./Solutions/integrations/sol_p1_only_preconfig.sh
bash ./Solutions/integrations/sol_pf_only_preconfig.sh
