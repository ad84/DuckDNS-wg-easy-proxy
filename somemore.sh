#!/usr/bin/env bash
export $(grep -v '^#' .env | xargs -d '\n') # import .env variables
RED='\033[0;31m'
NC='\033[0m' # No Color
GREEN='\033[0;32m'

mkdir -p admin-ca/$WG_ADMIN_NAME
mkdir admin-ca/private
mkdir public
echo -e "${RED}Generating Self-sgined CA for client access to web gui (HTTPS certs are signed by letsencrypt)."
echo -e "${NC}Please enter an export password for the pfx file when promted, press enter twice for no password."

# set up siging request files. For CA:
cat <<EOF > ./admin-ca/CAconfig.conf
[req] 
prompt = no 
encrypt_key = no 
default_md = sha512 
distinguished_name = dname 
 
[dname] 
CN = $WG_SERVER_HOST
emailAddress = $WG_ADMIN_EMAIL
EOF
# and for client:
cat <<EOF > ./admin-ca/UserConifg.conf
[req] 
prompt = no 
encrypt_key = no 
default_md = sha512 
distinguished_name = dname 
 
[dname] 
CN = $WG_ADMIN_NAME
emailAddress = $WG_ADMIN_EMAIL
EOF

openssl ecparam -genkey -name secp384r1 | openssl ec -out ./admin-ca/private/ec.key 
openssl req -new -x509 -days 3650 -key ./admin-ca/private/ec.key -out ./public/wireguard-admin-ca.crt -config ./admin-ca/CAconfig.conf
openssl ecparam -genkey -name prime256v1 | openssl ec -out ./admin-ca/$WG_ADMIN_NAME/$WG_ADMIN_NAME.key
openssl req -new -config ./admin-ca/UserConifg.conf -key ./admin-ca/$WG_ADMIN_NAME/$WG_ADMIN_NAME.key -out ./admin-ca/$WG_ADMIN_NAME/$WG_ADMIN_NAME.csr
openssl x509 -req -days 365 -in  ./admin-ca/$WG_ADMIN_NAME/$WG_ADMIN_NAME.csr -CA ./public/wireguard-admin-ca.crt -CAkey ./admin-ca/private/ec.key -set_serial 01 -out ./admin-ca/$WG_ADMIN_NAME/$WG_ADMIN_NAME.crt -sha512
openssl pkcs12 -export -out ./admin-ca/$WG_ADMIN_NAME/$WG_ADMIN_NAME.pfx -inkey ./admin-ca/$WG_ADMIN_NAME/$WG_ADMIN_NAME.key -in ./admin-ca/$WG_ADMIN_NAME/$WG_ADMIN_NAME.crt -certfile ./public/wireguard-admin-ca.crt

#clean up
rm ./admin-ca/CAconfig.conf ./admin-ca/UserConifg.conf 

echo -e "Confiuring Nginx container."
#todo - docker exec etc 


echo -e "${GREEN}All done."
echo -e "${NC}To gain access to the web admin you must now install the pxf file into your OS/browser on the client device."
echo -e "The file is loacted at ${RED}$PWD/admin-ca/$WG_ADMIN_NAME/$WG_ADMIN_NAME.pfx"
echo -e "${NC}Please copy to the client and install."

unset $(grep -v '^#' .env | sed -E 's/(.*)=.*/\1/' | xargs)
