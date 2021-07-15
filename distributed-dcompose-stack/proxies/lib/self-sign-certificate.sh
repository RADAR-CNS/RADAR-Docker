#!/bin/sh

set -e

if [ $# -ne 1 ]; then
  echo "Need SSL path parameter"
  exit 1
fi

SSL_PATH="$1"

if [ ! -e "${SSL_PATH}" ]; then
  mkdir -p "${SSL_PATH}"
fi
if [ ! -e "/var/lib/openssl/.well-known" ]; then
  mkdir -p /var/lib/openssl/.well-known
fi
apk update
apk add openssl

cd "${SSL_PATH}"
find . -type f -delete
openssl req -x509 -newkey rsa:4086 -subj '/C=XX/ST=XXXX/L=XXXX/O=XXXX/CN=localhost' -keyout privkey.pem -out cert.pem -days 3650 -nodes -sha256
cp cert.pem chain.pem
cp cert.pem fullchain.pem
