resource "yandex_compute_disk" "boot-disk-2" {
  name     = "boot-disk-2"
  type     = "network-hdd"
  zone     = "ru-central1-a"
  size     = "3"
  image_id = "fd8tervp942bbtdojq9e"
}


resource "yandex_compute_instance" "db" {
  name = "db"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot-disk-2.id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = false
  }

  metadata = {
    user-data = "${file("metadata.yaml")}"
  }

}


output "metadata-db" {
  value = yandex_compute_instance.server.metadata.user-data
}

resource "null_resource" "run-db" {
  depends_on = [
    yandex_compute_instance.server,
    yandex_compute_instance.db
  ]
  # triggers = {
  #   always_run = "${timestamp()}"
  # }

  provisioner "remote-exec" {
    inline = [
      "echo 'hello from DB!'",
      "sudo apt-get install redis -y"
    ]
    connection {
      type        = "ssh"
      user        = "yc-practitioner"
      private_key = file("~/.ssh/yc.key")
      host        = yandex_compute_instance.db.network_interface.0.ip_address

      bastion_host        = yandex_compute_instance.server.network_interface.0.nat_ip_address
      bastion_user        = "yc-practitioner"
      bastion_private_key = file("~/.ssh/yc.key")
    }
  }

  provisioner "file" {
    source      = "redis/redis.conf"
    destination = "/home/yc-practitioner/redis.conf"
    connection {
      type        = "ssh"
      user        = "yc-practitioner"
      private_key = file("~/.ssh/yc.key")
      host        = yandex_compute_instance.db.network_interface.0.ip_address

      bastion_host        = yandex_compute_instance.server.network_interface.0.nat_ip_address
      bastion_user        = "yc-practitioner"
      bastion_private_key = file("~/.ssh/yc.key")
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cp -rp /home/yc-practitioner/redis.conf /etc/redis/redis.conf",
      "sudo systemctl restart redis-server",
      "echo 'redis-server is ready'"
    ]
    connection {
      type        = "ssh"
      user        = "yc-practitioner"
      private_key = file("~/.ssh/yc.key")
      host        = yandex_compute_instance.db.network_interface.0.ip_address

      bastion_host        = yandex_compute_instance.server.network_interface.0.nat_ip_address
      bastion_user        = "yc-practitioner"
      bastion_private_key = file("~/.ssh/yc.key")
    }
  }

  # provisioner "file" {
  #   source      = "static/index.html"
  #   destination = "/home/yc-practitioner/static/index.html"
  #   connection {
  #     type        = "ssh"
  #     user        = "yc-practitioner"
  #     private_key = file("~/.ssh/yc.key")
  #     host        = yandex_compute_instance.server.network_interface.0.nat_ip_address
  #   }
  # }

}

output "internal_ip_address_db" {
  value = yandex_compute_instance.db.network_interface.0.ip_address
}
