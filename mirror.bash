#!/usr/bin/env bash

set -eux -o pipefail

cd $(dirname $0)

export MIRROR_USER=take-cheeze
export TEA_NAME=omv
export GITHUB_USER=take-cheeze

gh api --paginate "/users/${GITHUB_USER}/subscriptions?per_page=100" -q '.[].full_name' | xargs -d '\n' -L1 -P4 ./gitea-mirror.bash
gh api --paginate "users/${GITHUB_USER}/repos?per_page=100" -q '.[].full_name' | xargs -d '\n' -L1 -P4 ./gitea-mirror.bash
