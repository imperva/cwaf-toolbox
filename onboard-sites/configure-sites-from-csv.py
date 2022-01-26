#!/usr/bin/env python

import os
import sys
import csv
import logging
from subprocess import PIPE,Popen
import logging.handlers

############ ENV Settings ############
logging.basicConfig(filename="configure-sites-from-csv.log", filemode='w', format='%(name)s - %(levelname)s - %(message)s')

CSV_DATA = ["Domain,Status,Account ID,Site ID,CNAME"]
try:
    CSV_FILE_PATH = sys.argv[1]
except:
    print('Path to csv is missing, please specify a path to csv file you are looking to import. Example: python import-sites-from-csv.py "path/to/yourfile.csv"')
    exit()

def run():
    with open(CSV_FILE_PATH, newline='') as csvfile:
        csv_rows = csv.reader(csvfile, delimiter=',', quotechar='"')
        next(csv_rows)
        for row in csv_rows:
            site_id = row[3]
            if "N/A" not in site_id:
                logging.debug("configureing site: "+site_id)
                result = os.popen('incap site status '+site_id)
                print(result.read())
                # Add in all other incap cli calls to configure site here

if __name__ == '__main__':
    run()
