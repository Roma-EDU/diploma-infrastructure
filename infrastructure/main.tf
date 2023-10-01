provider "yandex" {
  service_account_key_file = file("../secrets/key.json")
  cloud_id  = var.yandex_cloud_id
  folder_id = var.yandex_folder_id
  zone      = var.yandex_zone
}

locals {
  is_prod   = terraform.workspace == "prod"
  cidr_blocks_a_map = {
    prod    = ["192.168.10.0/24"]
    stage   = ["192.168.60.0/24"]
  }
  cidr_blocks_b_map = {
    prod    = ["192.168.20.0/24"]
    stage   = ["192.168.70.0/24"]
  }
}

# Группа инстансов для размещения master-нод
resource "yandex_compute_instance_group" "k8s-masters" {
  name               = "k8s-masters-${terraform.workspace}"
  service_account_id = var.instances_service_account
  depends_on         = [
    yandex_vpc_network.main-network,
    yandex_vpc_subnet.k8s-subnet-a,
    yandex_vpc_subnet.k8s-subnet-b,
  ]
  
  # Шаблон экземпляра, к которому принадлежит группа экземпляров.
  instance_template {

    # Имена виртуальных машин, создаваемых в группе
    name = "${terraform.workspace}-master-{instance.index}"

    resources {
      cores  = 2
      memory = 4
      core_fraction = local.is_prod ? 100 : 20 # https://cloud.yandex.ru/docs/compute/concepts/performance-levels
    }

    boot_disk {
      initialize_params {
        image_id = var.ubuntu_2204
        type     = "network-nvme"
        size     = 30
      }
    }

    network_interface {
      network_id = yandex_vpc_network.main-network.id
      subnet_ids = [
        yandex_vpc_subnet.k8s-subnet-a.id,
        yandex_vpc_subnet.k8s-subnet-b.id,
      ]
      nat        = true   # Публичный IP-адрес
    }

    metadata = {
      ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
    }

    # Прерываемая
    scheduling_policy {
      preemptible = !local.is_prod
    }
  }

  scale_policy {
    fixed_scale {
      size = local.is_prod ? 3 : 1
    }
  }

  allocation_policy {
    zones = [
      var.yandex_zone_a,
      var.yandex_zone_b,
    ]
  }

  deploy_policy {
    max_expansion   = 1
    max_unavailable = 2
  }
}



# Группа инстансов для размещения worker-нод
resource "yandex_compute_instance_group" "k8s-workers" {
  name               = "k8s-workers-${terraform.workspace}"
  service_account_id = var.instances_service_account
  depends_on         = [
    yandex_vpc_network.main-network,
    yandex_vpc_subnet.k8s-subnet-a,
    yandex_vpc_subnet.k8s-subnet-b,
  ]
  
  # Шаблон экземпляра, к которому принадлежит группа экземпляров.
  instance_template {

    # Имена виртуальных машин, создаваемых в группе
    name = "${terraform.workspace}-worker-{instance.index}"

    resources {
      cores  = 2
      memory = 4
      core_fraction = local.is_prod ? 100 : 20 # https://cloud.yandex.ru/docs/compute/concepts/performance-levels
    }

    boot_disk {
      initialize_params {
        image_id = var.ubuntu_2204
        type     = "network-nvme"
        size     = 30
      }
    }

    network_interface {
      network_id = yandex_vpc_network.main-network.id
      subnet_ids = [
        yandex_vpc_subnet.k8s-subnet-a.id,
        yandex_vpc_subnet.k8s-subnet-b.id,
      ]
      nat        = true   # Публичный IP-адрес
    }

    metadata = {
      ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
    }

    # Прерываемая
    scheduling_policy {
      preemptible = !local.is_prod
    }
  }

  scale_policy {
    fixed_scale {
      size = local.is_prod ? 4 : 2
    }
  }

  allocation_policy {
    zones = [
      var.yandex_zone_a,
      var.yandex_zone_b,
    ]
  }

  deploy_policy {
    max_expansion   = 2
    max_unavailable = 2
  }
}