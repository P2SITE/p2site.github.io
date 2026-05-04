#!/bin/bash

#   CERTBOT_IDENTIFIER: The domain or IP address being authenticated
#   CERTBOT_VALIDATION: The validation string
#   CERTBOT_TOKEN: Resource name part of the HTTP-01 challenge (HTTP-01 only)
#   CERTBOT_REMAINING_CHALLENGES: Number of challenges remaining after the current challenge
#   CERTBOT_ALL_IDENTIFIERS: A comma-separated list of all identifiers challenged for the current certificate
#
# Additionally for cleanup:
#   CERTBOT_AUTH_OUTPUT: Whatever the auth script wrote to stdout

echo "Script: acme_auth_hook.sh"
# $CERTBOT_IDENTIFIER is passed from certbot
echo "CERTBOT_IDENTIFIER: '${CERTBOT_IDENTIFIER}'"
if [[ -z "$CERTBOT_IDENTIFIER" ]]; then
    CERTBOT_IDENTIFIER="p2site.github.io"
fi
echo "CERTBOT_IDENTIFIER: '${CERTBOT_IDENTIFIER}'"
# $CERTBOT_VALIDATION is passed from certbot
echo "CERTBOT_VALIDATION: '${CERTBOT_VALIDATION}'"
if [[ -z "$CERTBOT_VALIDATION" ]]; then
    CERTBOT_VALIDATION="YjCxR470Ie3JebPwgJ0lAUfGHGdgK804CtzBlReN3Tc.u8R966Ia_uEr-VLUfEMtvqAqAOwAdKMwHnqTKxR_hu4"
fi
echo "CERTBOT_VALIDATION: '${CERTBOT_VALIDATION}'"
# $CERTBOT_TOKEN is passed from certbot
echo "CERTBOT_TOKEN: '${CERTBOT_TOKEN}'"
if [[ -z "$CERTBOT_TOKEN" ]]; then
    CERTBOT_TOKEN="YjCxR470Ie3JebPwgJ0lAUfGHGdgK804CtzBlReN3Tc"
fi
echo "CERTBOT_TOKEN: '${CERTBOT_TOKEN}'"

#---
#layout: none
#permalink: .well-known/acme-challenge/YjCxR470Ie3JebPwgJ0lAUfGHGdgK804CtzBlReN3Tc
#---
#YjCxR470Ie3JebPwgJ0lAUfGHGdgK804CtzBlReN3Tc.u8R966Ia_uEr-VLUfEMtvqAqAOwAdKMwHnqTKxR_hu4

# =====================
# Update challenge file
#
echo "CHALLENGE_FILE: '${CHALLENGE_FILE}'"
cat << END_OF_CHALLENGE | tee "${CHALLENGE_FILE}"
---
layout: none
permalink: .well-known/acme-challenge/${CERTBOT_TOKEN}
---
${CERTBOT_VALIDATION}
END_OF_CHALLENGE
# Truncate last LF character
truncate -s -1 "$CHALLENGE_FILE"

# ==============================================
# Commit challenge file and push to pages branch
#
#GH_PAGES_BRANCH="gh-pages"
echo "GH_PAGES_BRANCH:  '${GH_PAGES_BRANCH}'"
#NO_CHALLENGE_TAG="__no_challenge"
echo "NO_CHALLENGE_TAG: '${NO_CHALLENGE_TAG}'"
echo "GITHUB_REF_NAME:  '${GITHUB_REF_NAME}'"
if [[ -n $(git status --porcelain) && -n "${GITHUB_REF_NAME}" ]]; then
    git fetch --all
    # TODO - move tagging into main workflow
    git tag -a "${NO_CHALLENGE_TAG}"
    git add -A
    git commit -am "Add challenge"
    #git push origin "${GITHUB_REF_NAME}"
    git push --force-with-lease origin "${GITHUB_REF_NAME}":"${GH_PAGES_BRANCH}"
    echo "Challenge force pushed to ${GH_PAGES_BRANCH}."
elif [[ -z "${GITHUB_REF_NAME}" ]]; then
    echo "###### WARNING: GITHUB_REF_NAME not set - no change commited - challenge must be updated manually!"
fi

# =======================================
# Wait for the challenge to become online
#
URL="https://${CERTBOT_IDENTIFIER}/.well-known/acme-challenge/${CERTBOT_TOKEN}"
MAX_RETRIES=30
count=0

echo "$(date '+%H:%M:%S') - Wait for ${URL} ..."
until curl --silent --fail --head --max-time 5 "${URL}" > /dev/null 2>&1; do
    count=$((count + 1))
    if [ "${count}" -ge "${MAX_RETRIES}" ]; then
        echo "###### ERROR: URL still not available after ${MAX_RETRIES} retries. Giving up."
        exit 1
    fi
    echo "$(date '+%H:%M:%S') - Attempt ${count}/${MAX_RETRIES} - URL not available, retrying in 10s..."
    sleep 10
done
echo "$(date '+%H:%M:%S') - URL is available: ${URL}"
