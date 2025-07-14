terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.80"
    }
  }
}

provider "yandex" {
  service_account_key_file = "key.json"
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = "ru-central1-a"
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "yandex_kms_symmetric_key" "bucket_key" {
  name              = var.kms_key_name
  default_algorithm = "AES_256"
  rotation_period   = "8760h" # 1 год
}

resource "yandex_storage_bucket" "secure_bucket" {
  bucket     = var.bucket_name
  default_storage_class = "STANDARD"
  max_size   = 10
  anonymous_access_flags {
    read = true
    list = false
  }

  website {
    index_document = "index.html"
  }

}