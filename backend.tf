resource "yandex_compute_disk" "boot-disk-1" {
  name        = "boot-disk-1"
  type        = "network-hdd"
  zone        = var.zone
  size        = "3"
  image_id    = "fd8okbvsmkrtdcuibv4j"
  description = "Backend boot disk. ${local.common_description}"
}

resource "yandex_compute_instance" "server" {
  name        = "server"
  description = "Backend server. ${local.common_description}"
  zone        = var.zone

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
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

resource "terraform_data" "run-server" {
  depends_on = [
    yandex_compute_instance.server,
    yandex_compute_instance.db
  ]

  provisioner "file" {
    source      = "./artifacts/package.deb"
    destination = "/home/${var.username}/package.deb"
    connection {
      type        = "ssh"
      user        = var.username
      private_key = file("~/.ssh/yc.key")
      host        = yandex_compute_instance.server.network_interface.0.nat_ip_address
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sleep 10",
      "sudo apt-get update && sudo apt-get install --only-upgrade dpkg -y",
      "sudo dpkg -i package.deb",
      "sudo sed -i 's/localhost/${yandex_compute_instance.server.network_interface.0.nat_ip_address}/g' /var/funfacts/static/index.html",
      "sudo sed -i 's/localhost/${yandex_compute_instance.db.network_interface.0.ip_address}/g' /lib/systemd/system/funfacts.service",
      "sudo systemctl start funfacts.service"
    ]
    connection {
      type        = "ssh"
      user        = var.username
      private_key = file("~/.ssh/yc.key")
      host        = yandex_compute_instance.server.network_interface.0.nat_ip_address
    }
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'replace ip adress in index.html'",
    ]
    connection {
      type        = "ssh"
      user        = var.username
      private_key = file("~/.ssh/yc.key")
      host        = yandex_compute_instance.server.network_interface.0.nat_ip_address
    }
  }
}

resource "yandex_vpc_network" "network-1" {
  name = "network-fun-facts-1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = var.zone
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
