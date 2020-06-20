# Vagrant - Vault CA

A Vagrant project that builds a VM running Vault to act as a CA.

Purpose is to provide a way to generate ssl certificates signed by an intermediate CA authority.

## Details

The Vault running inside the VM has two instances of the `pki` secrets engine configured at paths `pki_root` and `pki_int`.

The engine at the `pki_root` path is used as a root CA to sign intermediate CA certificates.

The engine at the `pki_int` path is used to issue leaf certificates signed by an intermediate CA. For this engine a role `req-cert` is configured that is allowed to generate leaf certificates for all domains. To generate a certificate follow the instructions [here](https://www.vaultproject.io/api/secret/pki#generate-certificate).

In the `vault-certs` directory there will be:

* the certificate of the root CA.
* the certificate if the intermediate CA.
* a script `req_vault_cert.sh` which can be used to generate certificates.

## Prerequisites

* Have [VirtualBox](https://www.virtualbox.org/wiki/Downloads) installed.
* Have [Vagrant](https://www.vagrantup.com/downloads) installed.

## Usage

* clone the repository.

```bash
git clone https://github.com/slavrd/vagrant-vault-ca.git
cd vagrant-vault-ca
```

* Build the Vagrant environment.

```bash
vagrant up
```

At this point Vault is running, initialized and unsealed in the VM. The root and intermediate CAs public keys are written out in the `vault-certs` directory.

* Login to the VM.

```bash
vagrant ssh
```

* Go to the synced folder between the VM and the host.

```bash
cd /vagrant/vault-certs
```

* Use the `req_vault_cert.sh` script to generate certificates. The script takes one argument. It can be either the common name to use to generate a certificate or the path to a file containing the payload of a certificate generation request made to Vault's pki secrets engine. For details of what the payload must be check Vault [documentation](https://www.vaultproject.io/api/secret/pki#generate-certificate).

Example payload:

```json
{
    "common_name": "example.com",
    "alt_names": "*.example.com, localhost",
    "ip_sans": "127.0.0.1",
    "ttl": "8760h",
}
```

Example script usage:

* generate certificate by providing common name only.

```bash
./req_vault_cert.sh www.example.com
```

* generate certificate using a file `payload.json` containing the request payload.

```bash
./req_vault_cert.sh ./payload.json
```
