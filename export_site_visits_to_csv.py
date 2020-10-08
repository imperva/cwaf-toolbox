import requests
import json

# Set authentication parameters: api_id and api_key
api_id = ''
api_key = ''

# Set the request url
url = 'https://my.imperva.com'
sitesList = ("your.domain.com")

# Set proper headers
headers = {
    "x-API-Id": api_id,
    "x-API-Key": api_key,
    "Content-Type":"application/x-www-form-urlencoded",
    "Accept":"application/json"
}

params = {}
# Make the HTTP request
response = requests.post(url+"/api/prov/v1/sites/list", params=params, headers=headers)

# Check for HTTP codes other than 200
if response.status_code != 200:
    print('Status:', response.status_code, 'Headers:', response.headers, 'Error Response:',response.json())
    exit()
# Decode the JSON response into a dictionary and use the data
sitesResponse = response.json()

for site in sitesResponse["sites"]:
    if site["domain"] in sitesList:
        CSV_NAME = "site_visits_"+str(site["site_id"])+".csv"
        open(CSV_NAME, 'w+').close()
        csv_file=open(CSV_NAME,"w+")
        CSV_DATA = ["siteId,clientIPs,country,countryCode,clientType,clientApplication,actions.requestResult,actions.url,threats.securityRule,threats.alertLocation,threats.securityRuleAction"]
        response = requests.post(url+"/api/visits/v1", params={"site_id":site["site_id"]}, headers=headers)
        visitsResponse = response.json()
        for visit in visitsResponse["visits"]:
            for action in visit["actions"]:
                for threat in action["threats"]:
                    ROW = []
                    ROW.append(str(visit["siteId"]))
                    ROW.append(','.join(visit["clientIPs"]))
                    ROW.append(','.join(visit["country"]))
                    ROW.append(','.join(visit["countryCode"]))
                    ROW.append(visit["clientType"])
                    ROW.append(visit["clientApplication"])
                    ROW.append(action["requestResult"])
                    ROW.append(action["url"])
                    ROW.append(threat["securityRule"])
                    ROW.append(threat["alertLocation"])
                    ROW.append(threat["securityRuleAction"])
                    CSV_DATA.append('"'+'","'.join(ROW)+'"')
        csv_file.write("\n".join(CSV_DATA))
        csv_file.close()

