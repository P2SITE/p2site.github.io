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
echo "GH_PAGES_BRANCH:     '${GH_PAGES_BRANCH}'"
echo "RESET_TAG:           '${RESET_TAG}'"
echo "GITHUB_REF_NAME:     '${GITHUB_REF_NAME}'"
echo "GITHUB_REPO:         '${GITHUB_REPO}'"
echo "GITHUB_PAGES_ACTION: '${GITHUB_PAGES_ACTION}'"
if [[ -n "${GITHUB_REF_NAME}" ]]; then
    git fetch --all
    # TODO - get pages branch name from env set by main workflow
    #git tag -a "${RESET_TAG}"
    git push --force-with-lease origin "refs/tags/${RESET_TAG}":"${GH_PAGES_BRANCH}"
    echo "Cleanup force pushed from refs/tags/${RESET_TAG} to ${GH_PAGES_BRANCH}."
    git reset --hard "origin/${GITHUB_REF_NAME}"
    echo "Local ${GITHUB_REF_NAME} has been reset to origin/${GITHUB_REF_NAME}."
    echo "Triggering '${GITHUB_PAGES_ACTION}' on branch '${GH_PAGES_BRANCH}' of '${GITHUB_REPO}'"
    #gh workflow run "${GITHUB_PAGES_ACTION}" --ref "${GH_PAGES_BRANCH}" --repo "${GITHUB_REPO}"
    gh workflow run "${GITHUB_PAGES_ACTION}" --ref "${GH_PAGES_BRANCH}"

elif [[ -z "${GITHUB_REF_NAME}" ]]; then
    echo "###### WARNING: GITHUB_REF_NAME not set - no reset pushed to ${GH_PAGES_BRANCH}!"
fi
