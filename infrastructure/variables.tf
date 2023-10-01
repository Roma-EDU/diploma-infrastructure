# ID своего облака
# https://console.cloud.yandex.ru/cloud?section=overview
variable "yandex_cloud_id" {
  default = "b1gjn3v7sno758hjjba0"
}

# Folder своего облака
# https://console.cloud.yandex.ru/cloud?section=overview
variable "yandex_folder_id" {
  default = "b1gr1vdb5g3ktr8v0877"
}

variable "instances_service_account" {
  default = "aje16dilsetnl7cjm5na"
}

# ID образа
# ID можно узнать с помощью команды yc compute image list
# Или взять из списка существующих https://console.cloud.yandex.ru/folders/b1gr1vdb5g3ktr8v0877/compute/create-instance
# нажав на i и прокрутив вниз до image_id
variable "ubuntu_2004" {
  default = "fd8mfc6omiki5govl68h"
}
variable "ubuntu_2204" {
  default = "fd80bm0rh4rkepi5ksdi"
}

variable "yandex_zone" {
  default = "ru-central1-a"
}

variable "yandex_zone_a" {
  default = "ru-central1-a"
}

variable "yandex_zone_b" {
  default = "ru-central1-b"
}