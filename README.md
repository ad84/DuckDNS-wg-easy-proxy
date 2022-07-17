# DuckDNS-wg-easy-proxy

Scripts for [DuckDNS](http://www.duckdns.org/) domain to automate nginx reverve proxy for [wg-easy](https://github.com/WeeJeWel/wg-easy). Uses [acme.sh](https://github.com/acmesh-official/acme.sh) (for) certifacte generation and automatic renewal) and docker compose. 

## How to use:


1. clone this repo
 ```
 git clone https://github.com/ad84/wg-easy-auto-proxy.git
 ```

2. cd into the project direcory, rename `example.env` to `.env` and change the default vaules & others as required.

3. run the inital install scrpit to bring the containers up and istall ssl certificates 
```
sudo ./setup.sh
```
4. the wg-easy admin page will now be availale at https://vpn.yourduckdomain.duckdns.org, everything else will return 404. The ssl certifactes will auto-renew every 60 days. 

## Setting up auth for the admin page with ssl client certificate
1. run ssl-client.sh 
```
sudo ./ssl-client.sh
```
2. Now to gain access to the web admin you must now install the client (WG_ADMIN_NAME) pxf file into your OS/browser on the client device (as well as the enter the password for wg-easy). The pfx file will be in the project root. Copy (scp, rysnc etc.) to you device. The pfx file can be resued on as many devices as required and is valid for one year. (By which time i may have written a renwal script :) ) 




