terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.80"
    }
  }
}

provider "yandex" {
  token     = var.token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = "ru-central1-a"
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "yandex_storage_bucket" "secure_bucket" {
  bucket     = "devops-ann-bucket-${random_id.bucket_suffix.hex}"
  access_key = var.access_key
  secret_key = var.secret_key
  max_size   = 10

  anonymous_access_flags {
    read  = true
    list  = false
  }

  website {
    index_document = "index.html"
  }

  encryption {
    kms_key_id = var.kms_key_id
  }
}