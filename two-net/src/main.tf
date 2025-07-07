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
  service_account_key_file = var.sa_key_path
}

# VPC
resource "yandex_vpc_network" "default" {
  name = "lamp-network"
}

resource "yandex_vpc_subnet" "public" {
  name           = "public-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.default.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

# Bucket и картинка
resource "yandex_storage_bucket" "image_bucket" {
  bucket     = var.bucket_name
  access_key = var.access_key
  secret_key = var.secret_key

  acl = "public-read"
}

resource "yandex_storage_object" "lamp_image" {
  bucket     = yandex_storage_bucket.image_bucket.bucket
  key        = "lamp.jpg"
  source     = "lamp.jpg"
  acl        = "public-read"
  access_key = var.access_key
  secret_key = var.secret_key
}

# Instance template
resource "yandex_compute_instance_group" "lamp_group" {
  name                = "lamp-group"
  service_account_id  = var.instance_sa_id
  instance_template {
    platform_id = "standard-v1"
    resources {
      cores  = 2
      memory = 2
    }
    boot_disk {
      initialize_params {
        image_id = "fd827b91d99psvq5fjit"
      }
    }
    network_interface {
      subnet_ids = [yandex_vpc_subnet.public.id]
      nat        = true
    }

    metadata = {
      user-data = <<EOF
#cloud-config
packages:
  - apache2
runcmd:
  - systemctl enable apache2
  - systemctl start apache2
  - echo '<html><body><h1>Hello from LAMP VM!</h1><img src="https://${yandex_storage_bucket.image_bucket.bucket}.storage.yandexcloud.net/lamp.jpg"></body></html>' > /var/www/html/index.html
EOF
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    zones = ["ru-central1-a"]
  }

  deploy_policy {
    max_unavailable = 1
    max_creating    = 1
    max_expansion   = 1
    max_deleting    = 1
  }

  health_check {
    http_options {
      port = 80
      path = "/"
    }
  }
}

# Load Balancer
resource "yandex_lb_network_load_balancer" "lamp_lb" {
  name = "lamp-nlb"

  listener {
    name        = "http-listener"
    port        = 80
    target_port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_compute_instance_group.lamp_group.load_balancer_target_group_id

    healthcheck {
      name = "http"
      http_options {
        port = 80
        path = "/"
      }
    }
  }
}
