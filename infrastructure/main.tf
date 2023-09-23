provider "yandex" {
  service_account_key_file = file("../secrets/key.json")
  cloud_id  = var.yandex_cloud_id
  folder_id = var.yandex_folder_id
  zone      = var.yandex_zone
}

locals {
  is_prod = terraform.workspace == "prod"
  memory_map = {
    default  = 4
    prod     = 8
    stage    = 2
  }
  cidr_blocks_a_map = {
    prod     = ["192.168.10.0/24"]
    stage    = ["192.168.80.0/24"]
  }
  cidr_blocks_b_map = {
    prod     = ["192.168.20.0/24"]
    stage    = ["192.168.90.0/24"]
  }
}