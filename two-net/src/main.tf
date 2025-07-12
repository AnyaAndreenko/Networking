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
  token     = var.token
  zone      = "ru-central1-a"
}

resource "yandex_vpc_network" "network" {
  name = "lamp-network"
}

resource "yandex_vpc_subnet" "public" {
  name           = "lamp-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_storage_bucket" "image_bucket" {
  bucket     = var.bucket_name
  access_key = var.access_key
  secret_key = var.secret_key
  max_size   = 10

  anonymous_access_flags {
    read = true
    list = false
  }

  website {
    index_document = "index.html"
  }
}

resource "yandex_compute_instance_group" "lamp_group" {
  name               = "lamp-group"
  folder_id          = var.folder_id
  service_account_id = var.instance_sa_id
  depends_on         = [yandex_storage_bucket.image_bucket]

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
      subnet_id = yandex_vpc_subnet.public.id
      nat       = true
    }

    metadata = {
      user-data = <<EOF
#cloud-config
runcmd:
  - echo '<html><body><h1>Hello from LAMP group</h1><img src="https://${var.bucket_name}.storage.yandexcloud.net/image.jpg" /></body></html>' > /var/www/html/index.html
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
  }

  health_check {
    interval_sec      = 10
    timeout_sec       = 5
    unhealthy_threshold = 2
    healthy_threshold = 2
    tcp_options {
      port = 80
    }
  }
}

resource "yandex_lb_target_group" "lamp_tg" {
  name = "lamp-target-group"

  target {
    subnet_id = yandex_vpc_subnet.public.id
    address   = "192.168.10.10" # временное значение — не используется напрямую с instance_group
  }
}

resource "yandex_lb_network_load_balancer" "lamp_lb" {
  name = "lamp-nlb"

  listener {
    name        = "listener"
    port        = 80
    target_port = 80
    protocol    = "tcp"
  }

  attached_target_group {
    target_group_id = yandex_compute_instance_group.lamp_group.application_load_balancer.0.target_group_id
    healthcheck {
      name = "http"
      http_options {
        port = 80
        path = "/"
      }
    }
  }
}
