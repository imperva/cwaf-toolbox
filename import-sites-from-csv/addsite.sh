#!/bin/sh
​
#define parameters which are passed in.
SITE=$1
CERT=$2
PASS=$3
​
#Add site
#incap site add www.imperva.com
addSiteResponse=`./python3 incap site add "$SITE"` 
echo $addSiteResponse
​
#Upload cert
#incap site upcert --private_key="/<cert_location>/selfsigned.key" --passphrase=password SITE_ID
UploadCertResponse=`./python3 incap site upcert --private_key="$CERT" --passphrase="$PASS" SITE_ID` 
echo $UploadCertResponse
​
#Add Rule
#incap site add_incaprule --name="Testing block crawlers" --action=RULE_ACTION_ALERT --filter="ClientType == Crawler" 123456
​
#Add Security Rule
#incap site security  --security_rule_action=block_ip sql_injection 123456
​
#Add ACL (blacklist)
#incap site acl --ips=107.232.12.4,102.232.22.99 blacklisted_ips 123456
​
#Add Whitelist
#incap site whitelist  --urls='/home,/example'  --countries='JM,CA' --continents='AF' --ips='192.168.1.1,172.21.12.0/24' --client_app_types='Browser' --client_apps='68'  --user_agents='curl' cross_site_scripting 123456
​
#Add cache rule
#incap site cache-rule --never_cache_resource_url=/help,login --never_cache_resource_pattern=prefix,contains 123456