#!/bin/bash

set -e

# need to get the remote.conf in there
# this isn't really needed since env are provided via docker.
cat > "$REMOTE_CONF_FILE_PATH" <<EOF
# REGISTRY_URL=http://registry.domain.tld:5000
EOF

# stub out the project.conf
cat > "$PROJECT_CONF_FILE_PATH" <<EOF
PRIMARY_DOMAIN="${LNPLAY_CLUSTER_UNDERLAY_DOMAIN}"
LNPLAY_SERVER_MAC_ADDRESS=${VM_MAC_ADDRESS}
LNPLAY_SERVER_HOSTNAME=${LNPLAY_HOSTNAME}

# CPU/mem is proportional to node count.
LNPLAY_SERVER_CPU_COUNT=${LNPLAY_SERVER_CPU_COUNT}
LNPLAY_SERVER_MEMORY_MB=${LNPLAY_SERVER_MEMORY_MB}
EOF

cat > "$SITE_CONF_PATH" <<EOF
DOMAIN_NAME=${LNPLAY_CLUSTER_UNDERLAY_DOMAIN}
EOF

cat > "$LNPLAY_ENV_FILE_PATH" <<EOL
# ${LNPLAY_ENV_FILE_PATH}
DOCKER_HOST=ssh://ubuntu@${LNPLAY_HOSTNAME}.${LNPLAY_CLUSTER_UNDERLAY_DOMAIN}
DOMAIN_NAME=${LNPLAY_EXTERNAL_DNS_NAME}
ENABLE_TLS=true
BTC_CHAIN=regtest
CHANNEL_SETUP=none
REGTEST_BLOCK_TIME=5
CLN_COUNT=${NODE_COUNT}
DEPLOY_CLAMS_REMOTE=false
DIRECT_LINK_FRONTEND_URL_OVERRIDE_FQDN=beta.clams.tech
CLIGHTNING_WEBSOCKET_EXTERNAL_PORT=${STARTING_EXTERNAL_PORT}
LNPLAY_SERVER_PATH=${LNPLAY_CONF_PATH}
CONNECTION_STRING_CSV_PATH=${CONNECTION_STRINGS_PATH}
PURGE_VOLUMES_ON_DOWN=true
CONNECT_NODES=false
RENEW_CERTS=false
EOL
