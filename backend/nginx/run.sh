#!/bin/bash

set -ex
cd "$(dirname "$0")"

OUTPUT_DIR=

# grab any modifications from the command line.
for i in "$@"; do
    case $i in
        --output-path=*)
            OUTPUT_DIR="${i#*=}"
            shift
        ;;
        *)
        echo "Unexpected option: $1"
        exit 1
        ;;
    esac
done


# # build the ln-ws-app if we're deploying it.
# LN_WS_PROXY_IMAGE_NAME="ln-ws-proxy:$LN_WS_PROXY_GIT_TAG"
# export LN_WS_PROXY_IMAGE_NAME="$LN_WS_PROXY_IMAGE_NAME"
# if [ "$DEPLOY_LN_WS_PROXY" = true ]; then
#     docker build --build-arg GIT_REPO_URL="$LN_WS_PROXY_GIT_REPO_URL" \
#     --build-arg VERSION="$LN_WS_PROXY_GIT_TAG" \
#     -t "$LN_WS_PROXY_IMAGE_NAME" \
#     ./ln-ws-proxy/
# fi


# stub out the nginx config
NGINX_CONFIG_PATH="$(pwd)/nginx.conf"
export NGINX_CONFIG_PATH="$NGINX_CONFIG_PATH"