terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">0.13"
}

provider "yandex" {
  zone = "ru-central1-a"
}

resource "yandex_compute_disk" "boot-disk-1" {
  name     = "boot-disk-1"
  type     = "network-hdd"
  zone     = "ru-central1-a"
  size     = "3"
  image_id = "fd8tervp942bbtdojq9e"
}

resource "yandex_compute_instance" "server" {
  name = "server"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot-disk-1.id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    user-data = "${file("metadata.yaml")}"
  }
}

output "metadata-server" {
  value = yandex_compute_instance.server.metadata.user-data
}

resource "null_resource" "run-server" {
  depends_on = [
    yandex_compute_instance.server,
    yandex_compute_instance.db
  ]
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "remote-exec" {
    inline = ["mkdir -p /home/yc-practitioner/static", "sudo killall fun-facts; echo fun-facts killed"]
    connection {
      type        = "ssh"
      user        = "yc-practitioner"
      private_key = file("~/.ssh/yc.key")
      host        = yandex_compute_instance.server.network_interface.0.nat_ip_address
    }
  }

  provisioner "file" {
    source      = "./artifacts/linux/fun-facts"
    destination = "/home/yc-practitioner/fun-facts"
    connection {
      type        = "ssh"
      user        = "yc-practitioner"
      private_key = file("~/.ssh/yc.key")
      host        = yandex_compute_instance.server.network_interface.0.nat_ip_address
    }
  }

  provisioner "remote-exec" {
    inline = ["mkdir -p /home/yc-practitioner/static"]
    connection {
      type        = "ssh"
      user        = "yc-practitioner"
      private_key = file("~/.ssh/yc.key")
      host        = yandex_compute_instance.server.network_interface.0.nat_ip_address
    }
  }

  provisioner "file" {
    source      = "static/index.html"
    destination = "/home/yc-practitioner/static/index.html"
    connection {
      type        = "ssh"
      user        = "yc-practitioner"
      private_key = file("~/.ssh/yc.key")
      host        = yandex_compute_instance.server.network_interface.0.nat_ip_address
    }
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'replace ip adress in index.html'",
      "sed -i 's/localhost/${yandex_compute_instance.server.network_interface.0.nat_ip_address}/g' /home/yc-practitioner/static/index.html",
      "echo 'starting server'",
      "chmod 711 /home/yc-practitioner/fun-facts",
      "nohup sudo /home/yc-practitioner/fun-facts -redisAddress ${yandex_compute_instance.db.network_interface.0.ip_address}:6379 &",
      "sleep 2", # dirty-hack to start detached process from https://stackoverflow.com/questions/36207752/how-can-i-start-a-remote-service-using-terraform-provisioning
      "echo 'server started!'",
    ]
    connection {
      type        = "ssh"
      user        = "yc-practitioner"
      private_key = file("~/.ssh/yc.key")
      host        = yandex_compute_instance.server.network_interface.0.nat_ip_address
    }
  }

}

# resource "yandex_compute_instance" "db" {
#   name = "terraform2"

#   resources {
#     cores  = 2
#     memory = 2
#   }


#   network_interface {
#     subnet_id = yandex_vpc_subnet.subnet-1.id
#     nat       = true
#   }

#   metadata = {
#     ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
#   }
# }

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
  route_table_id = yandex_vpc_route_table.rt.id
}


resource "yandex_vpc_gateway" "nat_gateway" {
  name = "test-gateway"
  shared_egress_gateway {
  }
}

resource "yandex_vpc_route_table" "rt" {
  name       = "test-rt"
  network_id = yandex_vpc_network.network-1.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

output "internal_ip_address_server" {
  value = yandex_compute_instance.server.network_interface.0.ip_address
}

output "external_ip_address_server" {
  value = yandex_compute_instance.server.network_interface.0.nat_ip_address
}
