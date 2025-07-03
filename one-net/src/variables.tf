variable "zone" {
  default = "ru-central1-a"
}

variable "public_cidr" {
  default = "192.168.10.0/24"
}

variable "private_cidr" {
  default = "192.168.20.0/24"
}

variable "nat_image_id" {
  default = "fd80mrhj8fl2oe87o4e1"
}

variable "nat_internal_ip" {
  default = "192.168.10.254"
}

variable "folder_id" {
  description = "Yandex Cloud Folder ID"
}

variable "ssh_public_key" {
  default = "~/.ssh/id_ed25519.pub"
}


