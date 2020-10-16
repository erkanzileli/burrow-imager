#! /bin/sh

GITHUB_ORG="linkedin"
GITHUB_REPO="Burrow"

DOCKER_HUB_USER="erkanzileli"
DOCKER_HUB_REPO="burrow"

set -e

echo "GITHUB_ORG:$GITHUB_ORG GITHUB_REPO:$GITHUB_REPO DOCKER_HUB_USER:$DOCKER_HUB_USER DOCKER_HUB_REPO:$DOCKER_HUB_REPO \n"

echo "Fetching 'latest' release of $GITHUB_ORG/$GITHUB_REPO"

LATEST_RELEASE=$(curl --silent --show-error --fail -X GET "https://api.github.com/repos/$GITHUB_ORG/$GITHUB_REPO/releases/latest")
LATEST_RELEASE_NAME=$(jq -r '.name' <<<"${LATEST_RELEASE}")
LATEST_RELEASE_DATE=$(jq -r '.published_at' <<<"${LATEST_RELEASE}")

echo "LATEST_RELEASE_NAME:$LATEST_RELEASE_NAME LATEST_RELEASE_DATE:$LATEST_RELEASE_DATE \n"

echo "Fetching 'latest' tag of $DOCKER_HUB_USER/$DOCKER_HUB_REPO"

LATEST_IMAGE=$(curl --silent --show-error --fail -X GET https://hub.docker.com/v2/repositories/$DOCKER_HUB_USER/$DOCKER_HUB_REPO/tags/latest)
LATEST_IMAGE_DATE=$(jq -r '.last_updated' <<<"${LATEST_IMAGE}")

echo "LATEST_IMAGE_DATE:$LATEST_IMAGE_DATE \n"

if [[ "$LATEST_RELEASE_DATE" < "$LATEST_IMAGE_DATE" ]]; then

    if [[ $LATEST_RELEASE_NAME == v* ]]; then
        VERSION="${LATEST_RELEASE_NAME:1}"
    else
        VERSION="$LATEST_RELEASE_NAME"
    fi

    BUILD_DIR="/tmp/$GITHUB_REPO"

    echo "Starting build for version $VERSION"

    rm -rf $BUILD_DIR
    echo "Cloning $GITHUB_ORG/$GITHUB_REPO into /tmp/$GITHUB_REPO"
    git clone -c advice.detachedHead=false --quiet --depth=1 --branch "$LATEST_RELEASE_NAME" "https://github.com/$GITHUB_ORG/$GITHUB_REPO.git" "/tmp/$GITHUB_REPO"

    echo "Building $DOCKER_HUB_USER/$DOCKER_HUB_REPO:$VERSION and $DOCKER_HUB_USER/$DOCKER_HUB_REPO:latest"
    docker build --quiet -t "$DOCKER_HUB_USER/$DOCKER_HUB_REPO:$VERSION" -t "$DOCKER_HUB_USER/$DOCKER_HUB_REPO:latest" $BUILD_DIR

    echo "Pushing images"
    docker push "$DOCKER_HUB_USER/$DOCKER_HUB_REPO:$VERSION"
    docker push "$DOCKER_HUB_USER/$DOCKER_HUB_REPO:latest"

    echo "Done"
else
    echo "There is no need to build an image"
fi
