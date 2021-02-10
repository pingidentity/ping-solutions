#!/bin/bash
# Script to test PingOne instance against trial specifications

echo "Performing tests on reverted state"
echo "Performing Workforce validation"
cat ./.gitlab-ci/cypress.d/integration/tests/reverted_state_check.base | \
awk -v env="$ENV_ID" -v cu="$CONSOLE_USERNAME" -v cp="$CONSOLE_PASSWORD" \
-v eid="ENV_ID" -v tu="TEST_USERNAME" -v tp="TEST_PASSWORD" \
'{sub(eid,env)} {sub(tu,cu)} {sub(tp,cp)}1' >\
./.gitlab-ci/cypress.d/integration/tests/reverted_state_check.js 


docker run -it --ipc=host -v $PWD/.gitlab-ci/cypress.d:/e2e -w /e2e -entrypoint=cypress cypress/included:6.3.0 --browser chrome run --record --key $CYPRESS_RECORD_KEY

rm ./.gitlab-ci/cypress.d/integration/tests/reverted_state_check.js 