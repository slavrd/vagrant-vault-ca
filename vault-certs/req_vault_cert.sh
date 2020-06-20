#!/usr/bin/env bash
# requests a cerificate from vault and isntalls it with a test site in nginx
#
# Arguments:
# 1st (oprional): CN for the certificate or a path to the payload for an API request to vault's /pki/issue/:name endpoint
#                 https://www.vaultproject.io/api/secret/pki#generate-intermediate
#                 Defaults to CN: "test.my-domain.com"
#
# Requires: Vault address and Vault token set to $VAULT_ADDR and $VAULT_TOKEN

# setup vars based on the provided arguments
if [ -f "$1" ]; then
    REQ_PAYOAD=${1}
    CERT_CN=$(jq -r '.common_name' ${REQ_PAYOAD})
elif [ "$1" == "" ]; then
    CERT_CN="test.my-domain.com"
else
    CERT_CN=${1}
fi


VAULT_RESP_FILE="/tmp/vault_response.json"

# request certificate from Vault
if [ -z "$REQ_PAYOAD" ]; then
    curl -sSf \
        --header "X-Vault-Token: $VAULT_TOKEN" \
        --request "POST" \
        --data "{ \"common_name\": \"$CERT_CN\", \"ttl\": \"2190h\" }" \
        $VAULT_ADDR/v1/pki_int/issue/cert-req \
        | jq -r .data > $VAULT_RESP_FILE
else
    curl -sSf \
        --header "X-Vault-Token: $VAULT_TOKEN" \
        --request "POST" \
        --data @$REQ_PAYOAD \
        $VAULT_ADDR/v1/pki_int/issue/cert-req \
        | jq -r .data > $VAULT_RESP_FILE
fi

# parse vault response and install chainde certificates and key
CERT_OUT_PATH=${CERT_CN}
[ -d ${CERT_OUT_PATH} ] || mkdir -p ${CERT_OUT_PATH}

jq -r '.certificate' $VAULT_RESP_FILE | tee "$CERT_OUT_PATH/cert.crt" > /dev/null
jq -r '.ca_chain[]' $VAULT_RESP_FILE | tee "$CERT_OUT_PATH/chain.crt" > /dev/null
jq -r '.private_key' $VAULT_RESP_FILE | tee "$CERT_OUT_PATH/priv.key" > /dev/null

# clean up response file
rm $VAULT_RESP_FILE