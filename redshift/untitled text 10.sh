#!/bin/bash

CHAIN_ID=${CHAIN_ID:-Furychain-fork}
USER=${USER:-foobar}
MONIKER=${MONIKER:-node001}
EXPORTED_GENESIS_URL=${EXPORTED_GENESIS_URL:-"https://orai.s3.us-east-2.amazonaws.com/export-genesis.json"}

if [[ ! -f "./genesis.json" ]]
then
    wget -O ./genesis.json $EXPORTED_GENESIS_URL
fi

if [[ -d ".fury/data" ]] 
then
    echo 'Already has data/ directory. Nothing to do!'
else

    AMOUNT="$(jq '.app_state.bank.balances[] | select(.address | contains("oraifl48vsnmsdzcv85q5d2q4z5ajdha8yu3xglvcy")).coins[0].amount | tonumber' genesis.json)fury"

    rm -rf "$PWD"/.fury

    fury init --chain-id $CHAIN_ID "$MONIKER"

    sed -i -e 's/keyring-backend *= *.*/keyring-backend = \"test\"/g' ./.fury/config/client.toml
    sed -i -e 's/chain-id *= *.*/chain-id = \"$CHAIN_ID\"/g' ./.fury/config/client.toml
    sed -i -e 's/broadcast-mode *= *.*/broadcast-mode = \"block\"/g' ./.fury/config/client.toml
    sed -i -e 's/node *= *.*/node = \"tcp:\/\/0.0.0.0:36657\"/g' ./.fury/config/client.toml

    fury keys add $USER 2>&1 | tee account.txt

    # hardcode the validator account for this instance
    fury add-genesis-account $USER "100000000000000fury" --keyring-backend test

    fury add-genesis-account 'fury18hr8jggl3xnrutfujy2jwpeu0l76azprlvgrwt' "100000000000000fury" --keyring-backend test

    sed -i -e 's/enabled-unsafe-cors *= *.*/enabled-unsafe-cors = true/g' ./.fury/config/app.toml
    sed -i -e 's/cors_allowed_origins *= *.*/cors_allowed_origins = \[\"*\"\]/g' ./.fury/config/config.toml
    sed -i -e 's/\<laddr\> *= *.*/laddr = \"tcp:\/\/0.0.0.0:36657\"/g' ./.fury/config/config.toml # replace exactly the string laddr with\< and \>

    # submit a genesis validator tx
    ## Workraround for https://github.com/cosmos/cosmos-sdk/issues/8251
    fury gentx $USER 50000000000000fury --chain-id=$CHAIN_ID -y

    fury collect-gentxs

    fury validate-genesis

    # cat $PWD/.fury/config/genesis.json | jq .app_state.genutil.gen_txs[0] -c > "$MONIKER"_validators.txt

    echo "The genesis initiation process has finished ..."
fi