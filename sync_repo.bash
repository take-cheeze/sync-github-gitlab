#!/usr/bin/env bash

set -eux -o pipefail

cd $(dirname $0)/repos

repo=$1
u=$(dirname "${repo}")

b=$(basename "${repo}")
if [ -d "${b}" ] ; then
    pushd "${b}"
    git lfs fetch --all
    git fetch origin -Pp
    popd
else
    git clone "https://github.com/${repo}.git"
fi

cd "${b}"

# Create gitlab repository if not exist
if ! git remote get-url gitlab ; then
    if [ -v GITLAB_USER_ID ] ; then
        u_id=$GITLAB_USER_ID
    else
        u_id=$(glab api "/users?username=${u}" | jq -r '.[0].id')
    fi

    yes | glab project create -s "${b}" || echo "already created"
    git remote add gitlab "${GITLAB_HOST}/${repo}.git"
fi

default_branch=$(basename $(git symbolic-ref refs/remotes/origin/HEAD --short))
git remote set-head origin --delete
git push --force gitlab "refs/remotes/origin/${default_branch}:refs/heads/${default_branch}"
git push --tags --force gitlab "refs/remotes/origin/*:refs/heads/*"
