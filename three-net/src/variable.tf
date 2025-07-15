variable "cloud_id" {}
variable "folder_id" {}
#variable "token" {}

variable "bucket_name" {
  default = "my-site"
}
variable "kms_key_name" {
  default = "secure-bucket-key"
}
#variable "access_key" {}
#variable "secret_key" {}