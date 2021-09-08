variable "api_id" {}
variable "api_key" {}
variable "secret_store_name" {}
variable "site_id" {
  type = list(string)
}
variable "aws_resource_prefix" {}
variable "account_id" {}
variable "bucket_name" {}
variable "aws_region" {}
variable "algorithm" {default = "RSA"}
variable "reg_email" {default = "your@email.com"}
variable "subject_organization" {default = "Your Company Name"}
variable "subject_organizational_unit" {default = "Your_Business_Unit"}
variable "subject_country" {default = "US"}
variable "subject_postal_code" {default = "12345"}
variable "locality" {default = "San Mateo"}
variable "serial_number" {default = "1"}
variable "naked_domain" {default = "yourdomainhere.com"}
variable "sub_domain" {default = "nel"}
variable "report_to_params" {default = "account_id=$account_id&city=$city&country=$country&postalcode=$postalcode&state=$state&epoch=$epoch&longitude=$longitude&latitude=$latitude&site_id=$site_id&proxy_id=$proxy_id&pop=$pop&origin_pop=$origin_pop&session_id=$session_id&request_id=$request_id&asn=$asn"}
variable "log_type" {default = "nel"}
variable "max_age" {default = 60}
variable "success_fraction" {default = "0.1"}
variable "failure_fraction" {default = "1.0"}