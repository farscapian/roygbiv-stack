#!/bin/bash

set -eu
cd "$(dirname "$0")"


sleep 5

RETAIN_CACHE=false

for i in "$@"; do
    case $i in
        --retain-cache=*)
            RETAIN_CACHE="${i#*=}"
            shift
        ;;
        *)
        echo "Unexpected option: $1"
        exit 1
        ;;
    esac
done

# recache node addrs and pubkeys if not specified otherwise
if [ "$RETAIN_CACHE" = false ]; then
    echo "Caching node info..."

    rm -f "$LNPLAY_SERVER_PATH/node_addrs.txt"
    rm -f "$LNPLAY_SERVER_PATH/node_pubkeys.txt"
    rm -f "$LNPLAY_SERVER_PATH/any_offers.txt"

    for ((NODE_ID=0; NODE_ID<CLN_COUNT; NODE_ID++)); do
        pubkey=$(lncli --id=$NODE_ID getinfo | jq -r ".id")
        echo "$pubkey" >> "$LNPLAY_SERVER_PATH/node_pubkeys.txt"
    done

    echo "Node pubkeys cached"

    for ((NODE_ID=0; NODE_ID<CLN_COUNT; NODE_ID++)); do
        addr=$(lncli --id=$NODE_ID newaddr | jq -r ".bech32")
        echo "$addr" >> "$LNPLAY_SERVER_PATH/node_addrs.txt"
    done
    echo "Node addresses cached"

    # if we're deploying prisms, then we also standard any offers on each node.
    if [ "$CHANNEL_SETUP" = prism ] && [ "$BTC_CHAIN" != mainnet ]; then
        for ((NODE_ID=0; NODE_ID<CLN_COUNT; NODE_ID++)); do
            BOLT12_OFFER=$(lncli --id=${NODE_ID} offer any default | jq -r '.bolt12')
            echo "$BOLT12_OFFER" >> "$LNPLAY_SERVER_PATH/any_offers.txt"
        done

        echo "BOLT12 any offers cached"
    fi

fi

if [ "$BTC_CHAIN" != mainnet ]; then
    ./bitcoind_load_onchain.sh
fi

# With mainnet, all channel opens and spend must be done through a wallet app or the CLI
if [ "$BTC_CHAIN" = regtest ] || [ "$BTC_CHAIN" = signet ]; then
    ./cln_load_onchain.sh
fi

mapfile -t pubkeys < "$LNPLAY_SERVER_PATH/node_pubkeys.txt"

function connect_cln_nodes {
    # connect each node n to node [n+1]
    for ((NODE_ID=0; NODE_ID<CLN_COUNT; NODE_ID++)); do
        NEXT_NODE_ID=$((NODE_ID + 1))
        NODE_MOD_COUNT=$((NEXT_NODE_ID % CLN_COUNT))
        NEXT_NODE_PUBKEY=${pubkeys[$NODE_MOD_COUNT]}
        echo "Connecting 'cln-$NODE_ID' to 'cln-$NODE_MOD_COUNT' having pubkey '$NEXT_NODE_PUBKEY'."
        lncli --id="$NODE_ID" connect "$NEXT_NODE_PUBKEY" "cln-$NODE_MOD_COUNT" 9735
    done
}

if [ "$BTC_CHAIN" = regtest ]; then
    echo "INFO: bootstrapping the P2P network."

    if [ "$CLN_COUNT" -gt 1 ]; then
        connect_cln_nodes
    fi

    # if we're doing a prism CHANNEL_SETUP, 
    # we bootstrap the nodes so they're well-connected,
    # then we open up the canonical channel setup.
    if [ "$CHANNEL_SETUP" = prism ]; then
        # now call the script that opens the channels.
        ./create_prism_channels.sh
        #echo "skipping"
    fi

fi