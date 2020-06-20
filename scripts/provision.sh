#!/usr/bin/env bash
# Setup of the VM so it is "ready for use"

# Install basic packages.
PKGS="wget unzip curl jq vim"
which ${PKGS} || {
    sudo apt-get update -q -y
    sudo apd-get install -q -y ${PKGS}
}

# Set Vault environment variables for vagnrat user
grep VAULT_TOKEN ${HOME}/.profile || {
  echo 'export VAULT_TOKEN=$(sudo cat /etc/vault.d/.vault-token)' | tee -a $HOME/.profile
}

grep VAULT_ADDR ${HOME}/.profile || {
  echo 'export VAULT_ADDR=http://127.0.0.1:8200' | tee -a $HOME/.profile
}