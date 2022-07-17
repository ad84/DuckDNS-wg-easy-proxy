#!/usr/bin/env bash
export $(grep -v '^#' .env | xargs -d '\n') # import .env variables
RED='\033[0;31m'
NC='\033[0m' # No Color
GREEN='\033[0;32m'

# _uid="$(id -u)"
_uid=$SUDO_USER



mkdir -p ./admin-ca/$WG_ADMIN_NAME
mkdir ./admin-ca/private
mkdir ./admin-ca/public
echo -e "${GREEN}Generating Self-sgined CA for client access to web gui (HTTPS certs are signed by letsencrypt)."
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
openssl req -new -x509 -days 3650 -key ./admin-ca/private/ec.key -out ./admin-ca/public/wireguard-admin-ca.crt -config ./admin-ca/CAconfig.conf
openssl ecparam -genkey -name prime256v1 | openssl ec -out ./admin-ca/$WG_ADMIN_NAME/$WG_ADMIN_NAME.key
openssl req -new -config ./admin-ca/UserConifg.conf -key ./admin-ca/$WG_ADMIN_NAME/$WG_ADMIN_NAME.key -out ./admin-ca/$WG_ADMIN_NAME/$WG_ADMIN_NAME.csr
openssl x509 -req -days 365 -in  ./admin-ca/$WG_ADMIN_NAME/$WG_ADMIN_NAME.csr -CA ./admin-ca/public/wireguard-admin-ca.crt -CAkey ./admin-ca/private/ec.key -set_serial 01 -out ./admin-ca/$WG_ADMIN_NAME/$WG_ADMIN_NAME.crt -sha512
openssl pkcs12 -export -out ./$WG_ADMIN_NAME.pfx -inkey ./admin-ca/$WG_ADMIN_NAME/$WG_ADMIN_NAME.key -in ./admin-ca/$WG_ADMIN_NAME/$WG_ADMIN_NAME.crt -certfile ./admin-ca/public/wireguard-admin-ca.crt
mkdir ./nginx/ssl/admin-ca
cp ./admin-ca/public/wireguard-admin-ca.crt ./nginx/ssl/admin-ca/

#clean up
chown $_uid:$_uid $WG_ADMIN_NAME.pfx

configure_container () {
echo -e "Confiuring Nginx container."
#todo - docker exec etc 
docker exec nginx sh -c 'mv /etc/nginx/conf.d/wg-easy-auth.conf.bak /etc/nginx/conf.d/wg-easy-auth.conf'
docker exec nginx sh -c 'mv /etc/nginx/conf.d/wg-easy.conf etc/nginx/conf.d/wg-easy.conf.bak'
docker exec nginx sh -c 'nginx -s reload'
}

configure_container

echo -e "${GREEN}All done."
echo -e "${NC}To gain access to the web admin you must now install the pxf file into your OS/browser on the client device."
echo -e "The file is loacted at ./$WG_ADMIN_NAME.pfx"
echo -e "${NC}Please copy to the client and install."

unset $(grep -v '^#' .env | sed -E 's/(.*)=.*/\1/' | xargs)
