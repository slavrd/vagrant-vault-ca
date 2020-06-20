#!/usr/bin/env bash
# Setup Vault CA authority
# Requires packages - jq

# check if Vault environemtn cars are set up and attempt to set defaults if needed
[ -z "$VAULT_ADDR" ] && export VAULT_ADDR="http://127.0.0.1:8200"
[ -z "$VAULT_TOKEN" ] && export VAULT_TOKEN=$(sudo cat /etc/vault.d/.vault-token)

# prepare directory for saving Vualt certificates
CERT_OUT_PATH="/vagrant/vault-certs"
[ -d ${CERT_OUT_PATH} ] || mkdir -p ${CERT_OUT_PATH}

# enable pki secret engine for the Root CA
vault secrets enable -path=pki_root pki
vault secrets tune -max-lease-ttl=87600h pki_root >/dev/null

# generate the root certificate 
vault write -field=certificate pki_root/root/generate/internal common_name="Vault CA" \
    ttl=87600h > $CERT_OUT_PATH/vault_root_ca.crt
echo "==> Vault root CA certificate placed in $CERT_OUT_PATH/vault_root_ca.crt"

# configure root CA's issuing and crl distribution urls
vault write pki_root/config/urls \
       issuing_certificates="http://127.0.0.1:8200/v1/pki_root/ca" \
       crl_distribution_points="http://127.0.0.1:8200/v1/pki_root/crl"

# create the Intermediate CA
vault secrets enable -path=pki_int pki
vault secrets tune -max-lease-ttl=43800h pki_int >/dev/null

# generate CSR for intermediate CA
vault write -format=json pki_int/intermediate/generate/internal \
    common_name="Vault Intermediate Authority" ttl="43800h" \
    | jq -r '.data.csr' > /tmp/pki_intermediate.csr

# sign the CSR with the root CA's certificate
vault write -format=json pki_root/root/sign-intermediate csr=@/tmp/pki_intermediate.csr \
    format=pem_bundle \
    ttl="17520h" \
    | jq -r '.data.certificate' > $CERT_OUT_PATH/vault_intermediate.pem

# import the signed intermediate CSR
vault write pki_int/intermediate/set-signed certificate=@$CERT_OUT_PATH/vault_intermediate.pem

# create a role that conrols the leaf certificates which will be issued
vault write pki_int/roles/cert-req \
    allow_any_name=true \
    allow_subdomains=true \
    max_ttl="4380h"
