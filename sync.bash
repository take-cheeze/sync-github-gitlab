#!/usr/bin/env bash

set -eux -o pipefail

USER=take-cheeze

cd $(dirname $0)

mkdir -p repos

export GITLAB_HOST=https://gitlab-web-ingress.tailf0b7b1.ts.net
export GITLAB_USER_ID=$(glab api "/users?username=${USER}" | jq -r '.[0].id')

gh api --paginate "users/${USER}/repos?per_page=100" -q '.[].full_name' | xargs -d '\n' -L1 -P4 ./sync_repo.bash
