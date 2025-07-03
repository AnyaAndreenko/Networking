
provider "yandex" {
  folder_id = var.folder_id
  zone      = var.zone
}

# VPC
resource "yandex_vpc_network" "default" {
  name = "my-vpc"
}

# Публичная подсеть
resource "yandex_vpc_subnet" "public" {
  name           = "public"
  zone           = var.zone
  network_id     = yandex_vpc_network.default.id
  v4_cidr_blocks = [var.public_cidr]
}

# Приватная подсеть
resource "yandex_vpc_subnet" "private" {
  name           = "private"
  zone           = var.zone
  network_id     = yandex_vpc_network.default.id
  v4_cidr_blocks = [var.private_cidr]
  route_table_id = yandex_vpc_route_table.private_rt.id
}

# NAT-инстанс
resource "yandex_compute_instance" "nat_instance" {
  name        = "nat-instance"
  zone        = var.zone
  hostname    = "nat-instance"
  platform_id = "standard-v1"

  resources {
    cores  = 2
    memory = 1
  }

  boot_disk {
    initialize_params {
      image_id = var.nat_image_id
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public.id
    ip_address         = var.nat_internal_ip
    nat                = true  # Публичный IP
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

# Публичная ВМ
resource "yandex_compute_instance" "public_vm" {
  name        = "public-vm"
  zone        = var.zone
  hostname    = "public-vm"
  platform_id = "standard-v1"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8n0g1oe7d1eip3qv2k"  # Ubuntu 22.04 или любой доступный
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

# Приватная ВМ
resource "yandex_compute_instance" "private_vm" {
  name        = "private-vm"
  zone        = var.zone
  hostname    = "private-vm"
  platform_id = "standard-v1"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8n0g1oe7d1eip3qv2k"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.private.id
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

# Таблица маршрутизации
resource "yandex_vpc_route_table" "private_rt" {
  name       = "private-route-table"
  network_id = yandex_vpc_network.default.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = var.nat_internal_ip
  }
}