variable "cloud_id" {}
variable "folder_id" {}


variable "bucket_name" {
  default = "devops-ann-bucket-secure"
}
variable "kms_key_name" {
  default = "secure-bucket-key"
}
