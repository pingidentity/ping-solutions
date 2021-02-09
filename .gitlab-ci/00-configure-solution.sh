#!/bin/bash
# Script to configure PingOne instance to trial specifications

echo "checking base configuration"
pwd
env
echo "$USER"
type jq
type docker
docker info
docker version
type docker-compose
docker-compose version
type envsubst
envsubst --version
type git
git --version
type sed

[ ! -d "$HOME"/.pingidentity ] && mkdir "$HOME"/.pingidentity
[ ! -f "$HOME"/.pingidentity/devops ] && \
  cat <<DEVOPS > "$HOME"/.pingidentity/devops
PING_IDENTITY_ACCEPT_EULA=${PING_IDENTITY_ACCEPT_EULA:-YES}
PING_IDENTITY_DEVOPS_USER=$PING_IDENTITY_DEVOPS_USER
PING_IDENTITY_DEVOPS_KEY=$PING_IDENTITY_DEVOPS_KEY
PING_IDENTITY_DEVOPS_HOME=${PING_IDENTITY_DEVOPS_HOME:-$HOME/projects/devops}
PING_IDENTITY_DEVOPS_REGISTRY=${PING_IDENTITY_DEVOPS_REGISTRY:-docker.io/pingidentity}
PING_IDENTITY_DEVOPS_TAG=${PING_IDENTITY_DEVOPS_TAG:-latest}
DEVOPS

echo "Performing base PingOne configuration"
echo "Performing PingOne configuration revertion"
echo "Environment ID is $ENV_ID"
echo "API URL path is $API_LOCATIONS"

#performing initial PingOne creation scripts
for script in ./Solutions/WF/$CURRENT_PIPELINE_VERSION/PingOne/*create.sh; do
  echo "Executing $script..."
  bash $script 
done

#performing initial PingOne set scripts
for script in ./Solutions/WF/$CURRENT_PIPELINE_VERSION/PingOne/*set.sh; do
  echo "Executing $script..."
  bash $script 
done

