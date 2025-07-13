terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.80"
    }
  }
}

provider "yandex" {
  service_account_key_file = file("key.json")
  cloud_id  = "b1gasmmc1h1g6r1rgd47"
  folder_id = "b1gicro1ra02h5iaig5l"
  zone      = "ru-central1-a"
}

variable "bucket_name" {
  default = "devops-ann-bucket-secure" # Уникальное имя
}

# KMS ключ
resource "yandex_kms_symmetric_key" "bucket_key" {
  name              = "bucket-encryption-key"
  default_algorithm = "AES_256"
  rotation_period   = "8760h" # 1 год
}

# Бакет с шифрованием и доступом из интернета
resource "yandex_storage_bucket" "secure_bucket" {
  bucket   = var.bucket_name
  max_size = 10

  anonymous_access_flags {
    read = true
    list = false
  }

  website {
    index_document = "index.html"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = yandex_kms_symmetric_key.bucket_key.id
        sse_algorithm     = "aws:kms"
      }
    }
  }
}