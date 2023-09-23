terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"

  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "terraform-state-storage-diploma"
    region     = "ru-central1-a"
    key        = "states/terraform.tfstate"

    skip_region_validation      = true
    skip_credentials_validation = true
  }
}