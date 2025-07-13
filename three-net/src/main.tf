terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.80"
    }
  }
}

provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = "ru-central1-a"
  token     = var.token
}

resource "yandex_kms_symmetric_key" "bucket_key" {
  name              = "bucket-key"
  default_algorithm = "AES_256"
  rotation_period   = "8760h" # 1 год
}

resource "yandex_vpc_network" "default" {
  name = "default-network"
}

resource "yandex_vpc_subnet" "default" {
  name           = "default-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.default.id
  v4_cidr_blocks = ["10.1.0.0/24"]
}

resource "yandex_storage_bucket" "secure_bucket" {
  bucket     = var.bucket_name
  access_key = var.access_key
  secret_key = var.secret_key

  default_storage_class = "STANDARD"
  max_size              = 10

  anonymous_access_flags {
    read  = true
    list  = false
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = yandex_kms_symmetric_key.bucket_key.id
        sse_algorithm     = "aws:kms"
      }
    }
  }

  website {
    index_document = "index.html"
  }
}
