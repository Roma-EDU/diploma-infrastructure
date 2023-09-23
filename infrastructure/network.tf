# 1. Общая VPC (одна на все workspace, потому что больше YC не разрешает без обращения в техподдержку)
resource "yandex_vpc_network" "main-network" {
  name        = "diploma-network"
  description = "VPC Дипломный практикум в Yandex.Cloud"
}

# 2. Публичная подсеть 
resource "yandex_vpc_subnet" "subnet-a" {
  name           = "public-a-${terraform.workspace}"
  zone           = var.yandex_zone_a
  network_id     = yandex_vpc_network.main-network.id
  v4_cidr_blocks = local.cidr_blocks_a_map[terraform.workspace]
}

resource "yandex_vpc_subnet" "subnet-b" {
  name           = "public-b-${terraform.workspace}"
  zone           = var.yandex_zone_b
  network_id     = yandex_vpc_network.main-network.id
  v4_cidr_blocks = local.cidr_blocks_b_map[terraform.workspace]
}