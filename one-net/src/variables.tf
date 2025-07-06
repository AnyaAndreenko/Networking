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

variable "ssh_public_key" {
  default = "~/.ssh/id_ed25519.pub"
}

variable "folder_id" {
  default = "b1gd1posuin0b321ncsr"
}

variable "cloud_id" {
  default = "b1gasmmc1h1g6r1rgd47"
}

variable "ssh_user" {
  default = "ann"
}


