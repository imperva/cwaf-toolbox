import requests
import logging

def makeCall(url, params, method="GET", data=None):
    headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json'
    }
    if data == None:
        content = None
    else:
        content = data

    if params != None:
        url = url+"?"+"&".join(params)
    try:
        if method == 'POST':
            logging.warning("API REQUEST (" + method + " " + url + ") " + str(content))
            response = requests.post(url, content, headers=headers, verify=False)
        elif method == 'GET':
            logging.warning("API REQUEST (" + method + " " + url + ") ")
            response = requests.get(url, headers=headers, verify=False)
        elif method == 'DELETE':
            logging.warning("API REQUEST (" + method + " " + url + ") ")
            response = requests.delete(url, headers=headers, verify=False)
        elif method == 'PUT':
            logging.warning("API REQUEST (" + method + " " + url + ") " + str(content))
            response = requests.put(url, content, headers=headers, verify=False)
        if response.status_code == 404:
            logging.warning("API ERROR (" + method + " " + url + ") status code: "+str(response.status_code))
        elif response.status_code != 200:
            logging.warning("API ERROR (" + method + " " + url + ") "+str(response.status_code)+" | response: "+json.dumps(response.json()))
        else:
            logging.warning("API RESPONSE (" + method + " " + url + ") status code: "+str(response.status_code))
        return response
    except Exception as e:
        logging.warning("ERROR - "+str(e))

