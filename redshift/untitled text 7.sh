#!/bin/sh
#set -o errexit -o nounset -o pipefail

echo -n "Enter passphrase:"
read -s PASSWORD
CHAIN_ID=${CHAIN_ID:-Redshift_5000-3}
USER=${USER:-tupt}
MONIKER=${MONIKER:-node001}

rm -rf "$PWD"/.fury

fury init --chain-id $CHAIN_ID "$MONIKER"

(echo "$PASSWORD"; echo "$PASSWORD") | fury keys add $USER 2>&1 | tee account.txt

# hardcode the validator account for this instance
(echo "$PASSWORD") | fury add-genesis-account $USER "100000000000000fury"

(echo "$PASSWORD") | fury add-genesis-account 'did:fury:iaa18hr8jggl3xnrutfujy2jwpeu0l76azprlvgrwt' "100000000000000fury"

sed -i "s/enabled-unsafe-cors *= *.*/enabled-unsafe-cors = true/g" .fury/config/app.toml
sed -i "s/cors_allowed_origins *= *.*/cors_allowed_origins = \[\"*\"\]/g" .fury/config/config.toml
sed -i "1,/\<laddr\>/{s/\<laddr\> *= *.*/laddr = \"tcp:\/\/0.0.0.0:26657\"/g}" .fury/config/config.toml # replace exactly the string laddr with\< and \>

# submit a genesis validator tx
## Workraround for https://github.com/cosmos/cosmos-sdk/issues/8251
(echo "$PASSWORD"; echo "$PASSWORD") | fury gentx $USER "$AMOUNT" --chain-id=$CHAIN_ID --amount="$AMOUNT" -y

fury collect-gentxs

fury validate-genesis

# cat $PWD/.fury/config/genesis.json | jq .app_state.genutil.gen_txs[0] -c > "$MONIKER"_validators.txt

echo "The genesis initiation process has finished ..."

