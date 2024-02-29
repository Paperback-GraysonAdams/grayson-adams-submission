#!/bin/bash

args="$@"

START_VERSION=$1
START_SHA=""
STOP_VERSION=$2
STOP_SHA=""

GITHUB_TOKEN="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"
GITHUB_BASE_URL="https://api.github.com/repos/packbackbooks/code-challenge-devops"

# Due to line breaks, we need to base64 encode raw JQ for each commit data object
# Line breaks are present in the verification signature fields returned by API
COMMITS=$(curl -s \
  -H "Accept: application/json" \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
 ${GITHUB_BASE_URL}/commits | jq -r '.[] | @base64')

# No line breaks in values, so unnecessary to base64 encode this one
# This places each tag JSON on a new line, to be parsed by the loop
TAGS=$(curl -s \
  -H "Accept: application/json" \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  ${GITHUB_BASE_URL}/tags | jq -c '.[]')


for tag in $TAGS; do
    name=$(echo $tag | jq -r '.name')
    sha=$(echo $tag | jq -r '.commit.sha')
    if [ "$name" = "$START_VERSION" ]
    then
      START_SHA=$sha
      continue
    elif [ "$name" = "$STOP_VERSION" ]
    then
      STOP_SHA=$sha
      continue
    fi
done

ITERATE=false
for commit in $COMMITS; do
    sha=$(echo "$commit" | base64 --decode | jq -r '.sha')
    short_sha="${sha:0:10}"
    commit_msg=$(echo "$commit" | base64 --decode | jq -r '.commit.message')
    author=$(echo "$commit" | base64 --decode | jq -r '.author.login')
    if [ "$sha" = "$STOP_SHA" ]; then
      ITERATE=true
    fi

    if [ $ITERATE = true ]; then
      correct="FALSE"
      pull_request=$(echo "$commit" | base64 --decode | jq -r '.parents | length > 1')
      if [[ $commit_msg == MGMT-* || $commit_msg == POD[A-C]-* || $pull_request = "true" ]]; then
        correct="TRUE"
      fi
      echo $short_sha $correct $author
    fi


    if [ "$sha" = "$START_SHA" ]; then
      ITERATE=false
    fi
done
