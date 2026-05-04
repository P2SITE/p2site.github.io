#!/bin/bash

#   CERTBOT_IDENTIFIER: The domain or IP address being authenticated
#   CERTBOT_VALIDATION: The validation string
#   CERTBOT_TOKEN: Resource name part of the HTTP-01 challenge (HTTP-01 only)
#   CERTBOT_REMAINING_CHALLENGES: Number of challenges remaining after the current challenge
#   CERTBOT_ALL_IDENTIFIERS: A comma-separated list of all identifiers challenged for the current certificate
#
# Additionally for cleanup:
#   CERTBOT_AUTH_OUTPUT: Whatever the auth script wrote to stdout

echo "Script: acme_cleanup_hook.sh"
# ==================================
# Remove challenge from pages branch
#
#GH_PAGES_BRANCH="gh-pages"
echo "GH_PAGES_BRANCH:  '${GH_PAGES_BRANCH}'"
#NO_CHALLENGE_TAG="__no_challenge"
echo "NO_CHALLENGE_TAG: '${NO_CHALLENGE_TAG}'"
echo "GITHUB_REF_NAME:  '${GITHUB_REF_NAME}'"
if [[ -n "${GITHUB_REF_NAME}" ]]; then
    git fetch --all
    # TODO - get pages branch name from env set by main workflow
    #git tag -a "${NO_CHALLENGE_TAG}"
    git push --force-with-lease origin "refs/tags/${NO_CHALLENGE_TAG}":"${GH_PAGES_BRANCH}"
    echo "Cleanup force pushed from refs/tags/${NO_CHALLENGE_TAG} to ${GH_PAGES_BRANCH}."
elif [[ -z "${GITHUB_REF_NAME}" ]]; then
    echo "###### WARNING: GITHUB_REF_NAME not set - no reset pushed to ${GH_PAGES_BRANCH}!"
fi
