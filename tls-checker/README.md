# TLS-Checker

[![license](https://img.shields.io/badge/license-imperva--community-blue.svg)](https://github.com/imperva/cwaf-toolbox/blob/master/LICENSE.md)

## Description

This python script will recursively look up all sites in a cloud WAF account, and validate what versions of TLS are supported in a .csv report.

## Getting Started

Download the latest files from the tls-checker folder.  Within this folder are 3 required files:

```
tls-checker.py
cwaf.py
template.config.json
```

The files should be copied to a system running python version 3+. 

The template.config.json file must be re-named config.json.  

## Configuration Options ##

The script has one configuration file, which lives in the same directory as the script.

### config.json ###

The `config.json` configuration file is where New Relic specific configuration lives. 

Example:

```
{
    "log_level": "debug",
    "baseurl": "https://my.incapsula.com",
    "cwaf_auth": {
      "api_id": "1234",
      "api_key": "your-key-here",
      "account_id": "5678"
    },
    "tlsList":[
        "tls1",
        "tls1_1",
        "tls1_2"
    ]
}
```

#### Config Options ####

`log_level` - _(optional)_ the log level. Valid values: `debug`, `info`, `warn`, `error`, `fatal`. Defaults to `info`.

`baseurl` - Baseurl should not be modified, as this is the production endpoint for the cloud WAF API.

`cwaf_auth.api_id` - Unique ID of a cloud WAF api user

`cwaf_auth.api_key` - Secret key for the individual api user

`cwaf_auth.account_id` - ID of the account the api user was created in.

`tlsList` - Array of teh various tls versions that can be validated using openssl. Defaults to tls1, tls1_1, tls1_2. 

 