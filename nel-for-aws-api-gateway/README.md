# NEL for AWS API Gateway

This project describes how to enable Network Error Logging (NEL) for your Cloud WAF site via AWS API Gateway.

## Instructions

[Download](https://github.com/imperva/cwaf-toolbox/blob/master/nel-for-aws-api-gateway/NEL-API-gateway-swagger.json) the following example swagger file, and update the following lines with your account specific calues.

1. Update `REPLACE-WITH-YOUR-ARN` line 60 with the arn of your specific role
    `"credentials": "REPLACE-WITH-YOUR-ARN",`

1. Update `REPLACE-WITH-YOUR-REGION` line 61 with your desired region, example: us-west-1, or us-east-1, etc.
    `"uri": "arn:aws:apigateway:REPLACE-WITH-YOUR-REGION:kinesis:action/PutRecords",`
