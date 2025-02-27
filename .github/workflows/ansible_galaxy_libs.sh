#!/bin/bash

function _export() {
    if [ -z "$1" ]; then
        echo "Missing argument"
        exit 1
    fi
    if [ -n "$GITHUB_ENV" ]; then
        echo "$1" >>"$GITHUB_ENV"
    fi
    # shellcheck disable=SC2163
    export "$1"
}

function checkTag() {
    GIT_TAG="$1"
    if [ -z "$GIT_TAG" ]; then
        echo "Missing GIT_TAG script argument"
        exit 2
    fi
    _export COLLECTION="${GIT_TAG/_v*/}"
    if [ -z "$COLLECTION" ]; then
        echo "Cannot parse collection from tag $GIT_TAG"
        exit 2
    fi
    _export GIT_ROOT_PATH="$(git rev-parse --show-toplevel)"
    if ! [ -f "${GIT_ROOT_PATH}/${COLLECTION}.yml" ]; then
        echo "Ansible collection $COLLECTION is not defined under ${GIT_ROOT_PATH}/${COLLECTION}.yml"
        exit 2
    fi
    COLLECTION_FQDN=$(jq -r '.[0].collections[0] // empty' <(yq . "${GIT_ROOT_PATH}/${COLLECTION}.yml"))
    if [ -z "${COLLECTION_FQDN/*./}" ]; then
        echo "Cannot parse ansible collection name from file ${GIT_ROOT_PATH}/${COLLECTION}.yml"
        exit 2
    fi
    if [ "${COLLECTION_FQDN/*./}" != "$COLLECTION" ]; then
        echo "Ansible collection $COLLECTION name mismatch with collection $COLLECTION_FQDN defined under file ${GIT_ROOT_PATH}/${COLLECTION}.yml"
        exit 2
    fi
    _export COLLECTION_NAMESPACE="${COLLECTION_FQDN/.*/}"
    if [ -z "$COLLECTION_NAMESPACE" ]; then
        echo "Cannot parse ansible COLLECTION_NAMESPACE from file ${GIT_ROOT_PATH}/${COLLECTION}.yml"
        exit 2
    fi
    _export COLLECTION_VERSION="${GIT_TAG/*_v/}"
    if [ -z "$COLLECTION_VERSION" ]; then
        echo "Cannot parse version from tag $GIT_TAG"
        exit 2
    fi
    if curl -LsS "https://galaxy.ansible.com/api/v3/plugin/ansible/content/published/collections/index/${COLLECTION_NAMESPACE}/${COLLECTION}/versions" | jq -r '.data[].version // empty' | grep -q -P "${COLLECTION_VERSION//./\\.}"; then
        echo "Version $COLLECTION_VERSION is already published to ansible galaxy $COLLECTION_FQDN"
        exit 2
    fi
    echo "Tag $GIT_TAG sanity check is successful"
}

function setVersion() {
    if ! [ -d "${GIT_ROOT_PATH}/${COLLECTION_NAMESPACE}" ]; then
        echo "Missing collection namespace root directory ${GIT_ROOT_PATH}/${COLLECTION_NAMESPACE}"
        exit 3
    fi
    if ! [ -d "${GIT_ROOT_PATH}/${COLLECTION_NAMESPACE}/${COLLECTION}" ]; then
        echo "Missing collection directory ${GIT_ROOT_PATH}/${COLLECTION_NAMESPACE}/${COLLECTION}"
        exit 3
    fi
    if ! [ -f "${GIT_ROOT_PATH}/${COLLECTION_NAMESPACE}/${COLLECTION}/galaxy.yml" ]; then
        echo "Missing galaxy file ${GIT_ROOT_PATH}/${COLLECTION_NAMESPACE}/${COLLECTION}/galaxy.yml"
        exit 3
    fi
    GALAXY_DATA=$(yq . "${GIT_ROOT_PATH}/${COLLECTION_NAMESPACE}/${COLLECTION}/galaxy.yml")
    if [ -z "$GALAXY_DATA" ]; then
        echo "Cannot parse yaml data from template file ${GIT_ROOT_PATH}/${COLLECTION_NAMESPACE}/${COLLECTION}/galaxy.yml"
        exit 3
    fi
    GALAXY_VERSION=$(jq -r '.version // empty' <<<"$GALAXY_DATA")
    if [ -z "$GALAXY_VERSION" ]; then
        echo "Cannot parse version to replace from template file ${GIT_ROOT_PATH}/${COLLECTION_NAMESPACE}/${COLLECTION}/galaxy.yml"
        exit 3
    fi
    yq -y . <(jq -r '.version = "'"$COLLECTION_VERSION"'"' <<<"$GALAXY_DATA") >"${GIT_ROOT_PATH}/${COLLECTION_NAMESPACE}/${COLLECTION}/galaxy.yml"
    echo "Version $COLLECTION_VERSION updated successfully to file ${GIT_ROOT_PATH}/${COLLECTION_NAMESPACE}/${COLLECTION}/galaxy.yml"
    cat "${GIT_ROOT_PATH}/${COLLECTION_NAMESPACE}/${COLLECTION}/galaxy.yml"
}

function build() {
    type ansible-galaxy >/dev/null 2>&1 || sudo apt-get install ansible-galaxy
    (cd "${GIT_ROOT_PATH}/${COLLECTION_NAMESPACE}/${COLLECTION}" && ansible-galaxy collection build)
    _export PACKAGE_PATH="${GIT_ROOT_PATH}/${COLLECTION_NAMESPACE}/${COLLECTION}/${COLLECTION_NAMESPACE}-${COLLECTION}-${COLLECTION_VERSION}.tar.gz"
    if ! [ -f "$PACKAGE_PATH" ]; then
        echo "Missing package $PACKAGE_PATH despite build finished successfully"
        exit 4
    fi
    PACKAGE_CHECKSUM=$(sha256sum "$PACKAGE_PATH" | awk '{print $1}')
    echo "Package built successfully to $PACKAGE_PATH with sha256sum $PACKAGE_CHECKSUM"
}

function publish() {
    if [ -z "$GALAXY_TOKEN" ]; then
        echo "Missing API token for galaxy. Please declare a GitHub secret named GALAXY_TOKEN"
        exit 5
    fi
    ansible-galaxy collection publish "$PACKAGE_PATH" --token "$GALAXY_TOKEN"
}

function checkPublication() {
    TTL=5
    INTERVAL=30
    while [ $TTL -gt 0 ]; do
        if curl -LsS "https://galaxy.ansible.com/api/v3/plugin/ansible/content/published/collections/index/${COLLECTION_NAMESPACE}/${COLLECTION}/versions" | jq -r '.data[].version // empty' | grep -q -P "${COLLECTION_VERSION//./\\.}"; then
            echo "Package version $COLLECTION_VERSION published successfully to ${COLLECTION_NAMESPACE}.${COLLECTION}"
            exit 0
        fi
        echo "Waiting ${INTERVAL}s for API to check package ${COLLECTION_NAMESPACE}.${COLLECTION} version $COLLECTION_VERSION publication ($TTL attempt(s) left)..."
        sleep $INTERVAL
        TTL=$((TTL - 1))
    done
    echo "An error has occured while publishing package ${COLLECTION_NAMESPACE}.${COLLECTION}: version $COLLECTION_VERSION not found after $TTL attempts with an interval of ${INTERVAL}s"
    exit 6
}
