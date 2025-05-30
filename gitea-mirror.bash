#!/usr/bin/env bash

set -eux -o pipefail

repo=$1

export ORIG_USER=$(dirname $1)
export ORIG_REPO=$(basename $1)

export TEA_CONFIG="${HOME}/.config/tea/config.yml"

URL=$(yq ".logins[] | select(.name=\"${TEA_NAME}\").url" "${TEA_CONFIG}")/api/v1
TEA_TOKEN=$(yq ".logins[] | select(.name=\"${TEA_NAME}\").token" "${TEA_CONFIG}")

CURL_OPTS=(-H 'Accept: application/json' -H "Authorization: token ${TEA_TOKEN}" -H 'Content-Type: application/json')

if [ -v GITHUB_USER ] && [ "${GITHUB_USER}" = "${ORIG_USER}" ] ; then
    org=${MIRROR_USER}
else
    org=${ORIG_USER}
    
    if ! curl "${CURL_OPTS[@]}" -f "${URL}/orgs/${org}" >/dev/null ; then
    cat >./tmp.json <<EOS
{
    "username": "${org}"
}
EOS
        curl -f -X POST "${URL}/orgs" "${CURL_OPTS[@]}" -d "@tmp.json" -i
    fi
fi

if ! curl "${CURL_OPTS[@]}" -f "${URL}/repos/${org}/${ORIG_REPO}" >/dev/null ; then
    cat >./tmp.json <<EOS
{
    "auth_username": "${ORIG_USER}",
    "auth_token": "$(gh auth token)",
    "clone_addr": "https://github.com/${ORIG_USER}/${ORIG_REPO}.git",
    "issues": true,
    "labels": true,
    "lfs": true,
    "milestones": true,
    "mirror": true,
    "mirror_interval": "24h",
    "private": false,
    "pull_requests": true,
    "releases": true,
    "repo_name": "${ORIG_REPO}",
    "repo_owner": "${org}",
    "service": "github",
    "wiki": true
}
EOS
    curl -f -X POST "${URL}/repos/migrate" "${CURL_OPTS[@]}" -d "@tmp.json" -i
fi

cat >./tmp.json <<EOS
{
    "enable_prune": false,
    "mirror_interval": "24h"
}
EOS
curl -f -X PATCH "${URL}/repos/${org}/${ORIG_REPO}" "${CURL_OPTS[@]}" -d "@tmp.json" -i
