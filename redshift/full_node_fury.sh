#!/bin/bash
set -eu

echo "Initializing full node"

# Fury home dir
FURY_HOME=$HOME/.fury

# Name of the network to bootstrap
CHAINID="redshift_4200-3"
# The address to run fury node
FURY_HOST="34.172.71.237"
# The port of the fury gRPC
FURY_GRPC_PORT="9090"
# Config directories for fury node
FURY_HOME_CONFIG="$FURY_HOME/config"
# Config file for fury node
FURY_NODE_CONFIG="$FURY_HOME_CONFIG/config.toml"
# App config file for fury node
FURY_APP_CONFIG="$FURY_HOME_CONFIG/app.toml"
# Chain ID flag
FURY_CHAINID_FLAG="--chain-id $CHAINID"
# Seeds IPs
FURY_SEEDS_DEFAULT_IPS="34.172.71.237,34.29.185.241"

read -r -p "Enter a name for your node [fury]:" FURY_NODE_NAME
FURY_NODE_NAME=${FURY_NODE_NAME:-fury}

read -r -p "Enter seeds ips [$FURY_SEEDS_DEFAULT_IPS]:" FURY_SEEDS_IPS
FURY_SEEDS_IPS=${FURY_SEEDS_IPS:-$FURY_SEEDS_DEFAULT_IPS}

default_ip=$(hostname -I | awk '{print $1}')
read -r -p "Enter your ip address [$default_ip]:" ip
ip=${ip:-$default_ip}

FURY_SEEDS=
for seedIP in ${FURY_SEEDS_IPS//,/ } ; do
  wget $seedIP:26657/status? -O $FURY_HOME/seed_status.json
  seedID=$(jq -r .result.node_info.id $FURY_HOME/seed_status.json)

  if [[ -z "${seedID}" ]]; then
    echo "Something went wrong, can't fetch $seedIP info: "
    cat $FURY_HOME/seed_status.json
    exit 1
  fi

  rm $FURY_HOME/seed_status.json

  FURY_SEEDS="$FURY_SEEDS$seedID@$seedIP:26656,"
done

# create home directory
mkdir -p $FURY_HOME

# ------------------ Init fury ------------------
echo "Creating $FURY_NODE_NAME node with chain-id=$CHAINID..."

# Initialize the home directory and add some keys
echo "Initializing chain"
fury $FURY_CHAINID_FLAG init $FURY_NODE_NAME

#copy genesis file
cp -r ../genesis/genesis-mainnet-1.json $FURY_HOME_CONFIG/genesis.json

echo "Updating node config"

# change config
crudini --set $FURY_NODE_CONFIG p2p addr_book_strict false
crudini --set $FURY_NODE_CONFIG p2p external_address "\"tcp://$ip:26656\""
crudini --set $FURY_NODE_CONFIG p2p seeds "\"$FURY_SEEDS\""
crudini --set $FURY_NODE_CONFIG rpc laddr "\"tcp://$FURY_HOST:26657\""

crudini --set $FURY_APP_CONFIG grpc enable true
crudini --set $FURY_APP_CONFIG grpc address "\"$FURY_HOST:$FURY_GRPC_PORT\""
crudini --set $FURY_APP_CONFIG api enable true
crudini --set $FURY_APP_CONFIG api swagger true

echo "The initialisation of $FURY_NODE_NAME is done"
