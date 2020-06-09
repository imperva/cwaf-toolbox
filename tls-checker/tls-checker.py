import datetime
import logging
import json
import cwaf
import re
import subprocess
from subprocess import PIPE,Popen

configfile = 'config.json'
CONFIG = {}
try:
    with open(configfile, 'r') as data:
        CONFIG = json.load(data)
        logging.warning("Loaded "+configfile+" configuration")
except:
    logging.warning("Missing \""+configfile+"\" file, create file named config.json referencing template.config.json")
    exit()

############ GLOBALS ############
TIMESTAMP = format(datetime.datetime.now()).replace(" ","_").split(".")[0]
CSV_NAME = "tls-checker-report_"+TIMESTAMP.replace(":","_")+".csv"
CSV_HEADERS = ["Account ID, Site ID, Domain, support_all_tls_versions"]
for tlsProto in CONFIG["tlsList"]:
    CSV_HEADERS.append(tlsProto)
logging.basicConfig(filename='tls-checker.log', filemode='w', format='%(name)s - %(levelname)s - %(message)s')

auth = [
    "api_id="+CONFIG["cwaf_auth"]["api_id"],
    "api_key="+CONFIG["cwaf_auth"]["api_key"],
    "account_id="+CONFIG["cwaf_auth"]["account_id"]
]

logging.warning("Creating CSV " + CSV_NAME)
open(CSV_NAME, 'w+').close()
csv=open(CSV_NAME,"w+")
csv.write(",".join(CSV_HEADERS)+"\n")
csv.close()

def getSubAccounts():
    account_ids = []
    params = auth[:]
    account_response = cwaf.makeCall(CONFIG["baseurl"]+"/api/prov/v1/account", params, "POST")
    account = account_response.json()
    account_ids.append(account["account_id"])
    if account["plan_id"][:3].lower()=="ent":
        # Get enterprise sub account list
        sub_accounts_response = cwaf.makeCall(CONFIG["baseurl"]+"/api/prov/v1/accounts/listSubAccounts", params, "POST")
        sub_accounts = sub_accounts_response.json()
        for account in sub_accounts["resultList"]:
            account_ids.append(account["sub_account_id"])
    else: 
        # Get reseller sub account list
        sub_accounts_response = cwaf.makeCall(CONFIG["baseurl"]+"/api/prov/v1/accounts/list", params, "POST")
        sub_accounts = sub_accounts_response.json()
        for account in sub_accounts["accounts"]:
            account_ids.append(account["account_id"])
    return(account_ids)

account_ids = getSubAccounts()
for account_id in account_ids:
    hasMoreSites = True
    page_num = 0
    while hasMoreSites==True:
        params = auth[:]
        params.append("page_size=100")
        params.append("page_num="+str(page_num))    
        get_sites_response = cwaf.makeCall(CONFIG["baseurl"]+"/api/prov/v1/sites/list", params, "POST")
        sites_response = get_sites_response.json()
        if len(sites_response["sites"])>0:
            for site in sites_response["sites"]:
                record = [
                    str(account_id),
                    str(site["site_id"]),
                    str(site["domain"]),
                    str(site["support_all_tls_versions"])
                ]
                pipe = Popen(['nslookup',site["domain"]], stdout=PIPE)
                output = pipe.communicate()
                print(output[0])
                print(str(output[0]).find("server can't find"))
                if str(output[0]).lower().find("can't find")!=-1:
                    print("server can't find")
                    record.append("n/a")
                    record.append("n/a")
                    record.append("n/a")
                else:
                    print("else")
                    for tlsProto in CONFIG["tlsList"]:
                        print(tlsProto)
                        pipe = Popen(['openssl','s_client','-connect',site["domain"]+':443','-'+tlsProto], stdout=PIPE)
                        output = pipe.communicate()
                        if str(output[0]).find("errno")!=-1:
                            record.append("n/a")
                        elif str(output[0]).find("no peer certificate available")!=-1:
                            record.append("False")
                        else:
                            record.append("True")
                    
                csv=open(CSV_NAME,"w+")
                csv.write(",".join(record)+"\n")
                csv.close()
            page_num+=1
        else:
            hasMoreSites=False
