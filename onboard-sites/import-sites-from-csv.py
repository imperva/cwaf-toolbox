#!/usr/bin/env python

import os
import sys
import json
import csv
import requests
import logging
import urllib
from subprocess import PIPE,Popen

PROCESSED_SITES = ["Domain,Status,Account ID,Site ID,CNAME"]
try:
    CSV_FILE_PATH = sys.argv[1]
except:
    print('Path to csv is missing, please specify a path to csv file you are looking to import. Example: python import-sites-from-csv.py "path/to/yourfile.csv"')
    exit()

def run():
    with open(CSV_FILE_PATH, newline='') as csvfile:
        csv_rows = csv.reader(csvfile, delimiter=',', quotechar='"')
        # next(csv_rows)
        for row in csv_rows:
            processed_row = ['N/A'] * 5
            processed_row[0] = row[0]
            result = os.popen('incap site add '+row[0])
            for attr in result.read().split("\n"):
                # if "ERROR" in attr[:5]:
                #     processed_row[1] = attr
                #     break
                if "Site status:" in attr:
                    processed_row[1] = attr.split(": ").pop()
                elif "Account ID:" in attr:
                    processed_row[2] = attr.split(": ").pop()
                elif "Site ID:" in attr:
                    processed_row[3] = attr.split(": ").pop()
                elif "The current CNAME Record for " in attr:
                    processed_row[4] = attr.split(" is ").pop()
            PROCESSED_SITES.append(','.join(processed_row))
        print('\n'.join(PROCESSED_SITES))
if __name__ == '__main__':
    run()
