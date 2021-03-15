variable "secret_store_name" {}
variable "site_id" {
  type = list(string)
}
variable "account_id" {}
variable "bucket_name" {}
variable "api_id" {}
variable "api_key" {}
variable "success_fraction" {default = "0.1"}
variable "failure_fraction" {default = "1.0"}