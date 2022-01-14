# Imperva NEL

This project deploys [Network Error Logging (NEL)](https://www.w3.org/TR/network-error-logging) via terraform configuring Imperva's Cloud WAF, and standing up several AWS resources, including: Lambda functions, API Gateway API, Kinesis Stream, S3, Firehose, IAM Policies, and Secret Manager.  You can update the template to add AWS resources through the same deployment process that updates your application code.

## Prerequisites and Dependencies
- Install [AWS CLI](https://aws.amazon.com/cli/)
- Install [Terraform](https://www.terraform.io/) 
- Create a valid [New Relic API Key](https://docs.newrelic.com/docs/apis/get-started/intro-apis/new-relic-api-keys/)
- Create a sercet store in [AWS Secrets Mananger](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html) with key as `NR_API_KEY` as shown below, inserting your valid New Relic API Key (created above in previous step).

    ![aws_secret_screenshot.png](screenshots/aws_secret_screenshot.png)<br/>

## Setup up the environment
- Copy and rename the `terraform.tfvars.template` file to `terraform.tfvars`, and set the following parameters:

    `aws_region` - _(required)_ the aws region to deploy in, example: `us-east-2`

    `secret_store_name` - _(required)_ the name of the secret store, example: `/NewRelic/Dev`

    `site_id` - _(required)_ an array of Cloud WAF site ids to deploy NEL on, example: `["12345","67890"]`

    `account_id` - _(required)_ the id of the account or sub account, example: `1234`

    `aws_resource_prefix` - _(required)_ a string value to prefix all resources created via Terraform in AWS, example: "nel-dev"

    `bucket_name` - _(required)_ the globally unique name of your S3 bucket in AWS, example: "your-unique-domain.here.com"

    `api_id` - _(required)_ the Cloud WAF api user api id, example: `12345`

    `api_key` - _(required)_ the Cloud WAF api user secret key, example: `AbCdE-12345-defgh-67890`

    `naked_domain` - _(required)_ the naked domain that you own and manage in AWS Route53, example: `companyname.com`

    `sub_domain` - _(optional)_ the sub-domain that will prepend the naked domain, example: `nel`

    `report_to_params` - _(optional)_ the possible variables in the "Report_To" header, example: `account_id=$account_id&city=$city&country=$country&postalcode=$postalcode&state=$state`

    `log_type` - _(optional)_ the log type sent to NewRelic for easier searching, example: `nel`

    `max_age` - _(optional)_ the lifetime of the policy, in seconds (in a similar way to e.g. HSTS policies are time-restricted). The referenced reporting group should have a lifetime at least as long as the NEL policy., example: `3600`

    `success_fraction` - _(optional)_ the floating point value between 0 and 1 which specifies the proportion of successful network requests to report., example: `0.1`

    `failure_fraction` - _(optional)_ the floating point value between 0 and 1 which specifies the proportion of failed network requests to report. , example: `1.0`

# Below variables are used to create a LetsEncrypt certificate.
- Optional if using ACME and LetsEncrypt to create certificate.

    `reg_email` - _(required)_ the contact email address for the account., example: `your@email.com`

    `subject_organization` - _(required)_ the Company Name, example: `Your Company Name`

    `subject_organizational_unit` - _(required)_ the organization you work in, example: `IT`

    `subject_country` - _(required)_ the two-letter country code of company, example: `US`

    `subject_postal_code` - _(required)_ the postal code of company, example: `111111`

    `locality` - _(required)_ the city of company, example: `Hometown`

    `serial_number` - _(required)_ the addition of this serial number allows for simple rotation ever 90 days, example: `1`

## Deploying the environment
- In the `nel-aws-for-new-relic` folder, run the following commands to initialize and deploy:  
    - `terraform init`
    - `terraform plan`
    - `terraform apply --auto-approve`
