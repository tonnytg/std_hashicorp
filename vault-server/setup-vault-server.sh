#!/bin/bash

mkdir -p ./vault_data/{audit,config,data,file,logs,userconfig/tls,plugins}

cat ./vault_data/config/vault-config.hcl << EOF
disable_cache       = true
disable_mlock       = true
ui                  = true
max_lease_ttl       = "2h"
default_lease_ttl   = "20m"
raw_storage_endpoint = "true"
disable_printable_check = "true"
cluster_addr        = "https://vault.test.lan:8201"
api_addr            = "https://vault.test.lan"

listener "tcp" {
  address                   = "0.0.0.0:8200"
  tls_disable               = false
  tls_client_ca_file        = "/vault/userconfig/tls/ca.crt"
  tls_cert_file             = "/vault/userconfig/tls/vault.crt"
  tls_key_file              = "/vault/userconfig/tls/vault.key"
  tls_disable_client_certs  = "true"
}

storage "raft" {
  node_id  = "vault-1"
  path     = "/vault/data"
}
EOF


openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 -out ca.crt \
    -subj "/CN=MyVaultCA"

openssl genrsa -out vault.key 4096
openssl req -new -key vault.key -out vault.csr \
    -subj "/CN=vault.my-domain.local" \
    -addext "subjectAltName = DNS:vault.cellihub.local, IP:127.0.0.1"

openssl x509 -req -in vault.csr -CA ca.crt -CAkey ca.key \
    -CAcreateserial -out vault.crt -days 365 -sha256

openssl genrsa -out vault.key 4096

openssl req -new -key vault.key -out vault.csr \
  -subj "/CN=vault.test.lan" \
  -addext "subjectAltName = DNS:vault.test.lan, DNS:localhost, IP:127.0.0.1"

openssl x509 -req \
  -in vault.csr \
  -CA ca.crt \
  -CAkey ca.key \
  -CAcreateserial \
  -out vault.crt \
  -days 365 \
  -sha256 \
  -extfile <(printf "subjectAltName=DNS:vault.cellihub.local,IP:127.0.0.1")



