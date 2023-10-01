# 1. Общая VPC (одна на все workspace, потому что больше YC не разрешает без обращения в техподдержку)
resource "yandex_vpc_network" "main-network" {
  name        = "my-network"
  description = "Shared VPC"
}

# 2.1. Публичная подсеть в зоне 'A'
resource "yandex_vpc_subnet" "k8s-subnet-a" {
  name           = "k8s-subnet-${terraform.workspace}-a"
  zone           = var.yandex_zone_a
  network_id     = yandex_vpc_network.main-network.id
  v4_cidr_blocks = local.cidr_blocks_a_map[terraform.workspace]
  depends_on     = [
    yandex_vpc_network.main-network,
  ]
}

# 2.2. Публичная подсеть в зоне 'B'
resource "yandex_vpc_subnet" "k8s-subnet-b" {
  name           = "k8s-subnet-${terraform.workspace}-b"
  zone           = var.yandex_zone_b
  network_id     = yandex_vpc_network.main-network.id
  v4_cidr_blocks = local.cidr_blocks_b_map[terraform.workspace]
  depends_on     = [
    yandex_vpc_network.main-network,
  ]
}