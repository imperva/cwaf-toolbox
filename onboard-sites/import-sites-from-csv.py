#!/usr/bin/env python

import time
import os
import sys
import csv
import logging
from subprocess import PIPE,Popen

############ ENV Settings ############
logging.basicConfig(filename="import-sites-from-csv.log", filemode='w', format='%(name)s - %(levelname)s - %(message)s')

BLOCK_RULES = ["sql_injection","cross_site_scripting","illegal_resource_access","remote_file_inclusion"]
CSV_DATA = ["Domain,Account ID,Status,Site ID,CNAME,sql_injection,cross_site_scripting,illegal_resource_access,remote_file_inclusion"]
try:
    CSV_FILE_PATH = sys.argv[1]
except:
    print('Path to csv is missing, please specify a path to csv file you are looking to import. Example: python import-sites-from-csv.py "path/to/yourfile.csv"')
    exit()

PROCESSED_CSV_FILE_NAME = "processed_sites.csv"
open(PROCESSED_CSV_FILE_NAME, 'w+').close()
csv_file=open(PROCESSED_CSV_FILE_NAME,"w+")

def run():
    with open(CSV_FILE_PATH, newline='') as csvfile:
        csv_rows = csv.reader(csvfile, delimiter=',', quotechar='"')
        next(csv_rows)
        for row in csv_rows:
            if len(row[0])>0:
                processed_row = ['N/A'] * 9
                processed_row[0] = row[0]
                if len(row)>1:
                    processed_row[1] = row[1]
                if len(row)>1 and row[1]!="N/A":
                    print("Adding site for domain '"+row[0]+"' account_id '"+row[1]+"'")
                    result = os.popen('incap site add --account_id='+row[1]+' '+row[0])
                else:
                    print("Adding site for domain '"+row[0]+"'")
                    result = os.popen('incap site add '+row[0])
                for attr in result.read().split("\n"):
                    if "Account ID:" in attr:
                        processed_row[1] = attr.split(": ").pop()
                    elif "Site status:" in attr:
                        processed_row[2] = attr.split(": ").pop()
                    elif "Site ID:" in attr:
                        processed_row[3] = attr.split(": ").pop()
                    elif "The current CNAME Record for " in attr:
                        processed_row[4] = attr.split(" is ").pop()
                
                for rule_type in BLOCK_RULES:
                    if processed_row[3] != "N/A":
                        result = os.popen('incap site security --security_rule_action=block_request '+rule_type+' '+processed_row[3])
                        print(result.read())

                print("Retrieving full site config for domain '"+row[0]+"' with site_id '"+processed_row[3]+"'")
                result = os.popen('incap site status '+processed_row[3])
                for attr in result.read().split("\n"):
                    if "SQL Injection is set to" in attr:
                        processed_row[5] = attr.split(" to ").pop()
                    elif "Cross Site Scripting is set to" in attr:
                        processed_row[6] = attr.split(" to ").pop()
                    elif "Illegal Resource Access is set to" in attr:
                        processed_row[7] = attr.split(" to ").pop()
                    elif "Remote File Inclusion is set to" in attr:
                        processed_row[8] = attr.split(" to ").pop()
                CSV_DATA.append(','.join(processed_row))    

        csv_file.write("\n".join(CSV_DATA))
        csv_file.close()
        
if __name__ == '__main__':
    run()
