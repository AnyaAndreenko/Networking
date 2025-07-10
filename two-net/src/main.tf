terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.80.0"
    }
  }
}

provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = "ru-central1-a"
  token     = var.token

  }

# Переменные вынесены в variables.tf

resource "yandex_vpc_network" "network" {
  name = "lamp-network"
}

resource "yandex_vpc_subnet" "public" {
  name           = "public-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["192.168.100.0/24"]
}

# Object Storage
resource "yandex_storage_bucket" "image_bucket" {
  access_key = var.access_key
  secret_key = var.secret_key
  bucket     = var.bucket_name

  acl = "public-read"

  website {
    index_document = "index.html"
  }
}

resource "yandex_storage_object" "image" {
  access_key = null
  secret_key = null
  bucket     = yandex_storage_bucket.image_bucket.bucket
  key        = "image.jpg"
  source     = "image.jpg" # Предполагается, что файл лежит рядом

  acl = "public-read"
}

# 3 LAMP-инстанса
resource "yandex_compute_instance" "lamp" {
  count       = 3
  name        = "lamp-${count.index}"
  platform_id = "standard-v1"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd827b91d99psvq5fjit" # LAMP
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
    user-data = <<EOF
#!/bin/bash
echo "<h1>LAMP VM ${count.index}</h1><img src='https://${yandex_storage_bucket.image_bucket.bucket}.storage.yandexcloud.net/image.jpg' width='400' />" > /var/www/html/index.html
EOF
  }
}

# Load Balancer
resource "yandex_lb_target_group" "tg" {
  name = "lamp-tg"

  target {
    subnet_id = yandex_vpc_subnet.public.id
    address   = yandex_compute_instance.lamp[0].network_interface[0].ip_address
  }
  target {
    subnet_id = yandex_vpc_subnet.public.id
    address   = yandex_compute_instance.lamp[1].network_interface[0].ip_address
  }
  target {
    subnet_id = yandex_vpc_subnet.public.id
    address   = yandex_compute_instance.lamp[2].network_interface[0].ip_address
  }
}

resource "yandex_lb_network_load_balancer" "lamp_lb" {
  name        = "lamp-lb"
  listener {
    name = "http"
    port = 80
    target_port = 80
    protocol = "tcp"
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.tg.id
    healthcheck {
      name = "http"
      http_options {
        port = 80
        path = "/"
      }
    }
  }
}
