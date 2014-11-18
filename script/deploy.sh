#!/bin/bash

set -ex

# Distribute built public files and publish the sha1 of this branch.
dist_tgz=$DEPLOY_S3_BUCKET/dist/$CIRCLE_SHA1.tgz
tar -cz resources/public/ | aws put --http $dist_tgz
echo $CIRCLE_SHA1 | aws put --http $DEPLOY_S3_BUCKET/branch/$CIRCLE_BRANCH

# Check for matching branch name on backend.
export GIT_SSH='./script/git-ssh-wrap.sh'
export KEYPATH="$HOME/.ssh/id_frontend-private"
backend_heads=$(git ls-remote --heads git@github.com:circleci/circle)
if echo $backend_heads | grep "refs/heads/$CIRCLE_BRANCH$" ; then
  backend_branch=$CIRCLE_BRANCH
else
  backend_branch=master
fi

# Trigger a backend build of this sha1.
circle_api=https://circleci.com/api/v1
tree_url=$circle_api/project/circleci/circle/tree/$backend_branch
http_status=$(curl -o /dev/null \
                   --silent \
                   --write-out '%{http_code}\n' \
                   --header "Content-Type: application/json" \
                   --data "{\"build_parameters\": {\"FRONTEND_DEPLOY_SHA1\": \"$CIRCLE_SHA1\"}}" \
                   --request POST \
                   -L $tree_url?circle-token=$BACKEND_CIRCLE_TOKEN)
[[ 201 = $http_status ]]
