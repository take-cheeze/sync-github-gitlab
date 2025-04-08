#!/usr/bin/env bash

set -eux -o pipefail

cd $(dirname $0)/repos

repo=$1
u=$(dirname "${repo}")
b=$(basename "${repo}")
copybara_dir=copybara-${b}

if [ "${u}" != "${TARGET_USER}" ] && ! glab api "/groups/${u}" > /dev/null ; then
    copybara_dir=copybara-${u}-${b}
    glab api -X POST /groups -F "path=${u}" -F "name=${u}"
fi

if ! glab project view "${repo}" > /dev/null ; then
    if [ -v GITLAB_USER_ID ] ; then
        u_id=$GITLAB_USER_ID
    else
        u_id=$(glab api "/users?username=${u}" | jq -r '.[0].id')
    fi

    yes | glab repo create -s "${repo}" || echo "already created"
fi


mkdir -p "${copybara_dir}"
pushd "${copybara_dir}"
cat <<EOS > "./copy.bara.sky"
git.mirror(
    name = "default",
    origin = "https://github.com/${repo}.git",
    destination = "${GITLAB_HOST}/${repo}.git",
)
EOS
copybara migrate --work-dir "$(pwd)" --force "copy.bara.sky"
popd

if [ -v _USE_GIT ] ; then
    if [ -d "${b}" ] ; then
        pushd "${b}"
        git lfs fetch --all
        git fetch origin -Pp
        popd
    else
        git clone "https://github.com/${repo}.git"
    fi

    cd "${b}"

    default_branch=$(basename $(git symbolic-ref refs/remotes/origin/HEAD --short))
    git remote set-head origin --delete
    git push --force gitlab "refs/remotes/origin/${default_branch}:refs/heads/${default_branch}"
    git push --tags --force gitlab "refs/remotes/origin/*:refs/heads/*"
fi
