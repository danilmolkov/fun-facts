resource "yandex_compute_disk" "boot-disk-2" {
  name     = "boot-disk-2"
  type     = "network-hdd"
  zone     = var.zone
  size     = "3"
  image_id = "fd8tervp942bbtdojq9e"
}


resource "yandex_compute_instance" "db" {
  name        = "db"
  description = "Database server by ${local.author}"
  zone        = var.zone

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
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

resource "terraform_data" "run-db" {
  depends_on = [
    yandex_compute_instance.server,
    yandex_compute_instance.db
  ]

  connection {
    type        = "ssh"
    user        = var.username
    private_key = file("~/.ssh/yc.key")
    host        = yandex_compute_instance.db.network_interface.0.ip_address

    bastion_host        = yandex_compute_instance.server.network_interface.0.nat_ip_address
    bastion_user        = var.username
    bastion_private_key = file("~/.ssh/yc.key")
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Hello from DB!'",
      "sleep 10",
      "sudo apt-get update",
      "sudo apt-get install redis python3 python3-pip unzip -y"
    ]
    connection {
      type        = "ssh"
      user        = var.username
      private_key = file("~/.ssh/yc.key")
      host        = yandex_compute_instance.db.network_interface.0.ip_address

      bastion_host        = yandex_compute_instance.server.network_interface.0.nat_ip_address
      bastion_user        = var.username
      bastion_private_key = file("~/.ssh/yc.key")
    }
  }

  provisioner "file" {
    source      = "redis/redis.conf"
    destination = "/home/yc-practitioner/redis.conf"
    connection {
      type        = "ssh"
      user        = var.username
      private_key = file("~/.ssh/yc.key")
      host        = yandex_compute_instance.db.network_interface.0.ip_address

      bastion_host        = yandex_compute_instance.server.network_interface.0.nat_ip_address
      bastion_user        = var.username
      bastion_private_key = file("~/.ssh/yc.key")
    }
  }

  provisioner "file" {
    source      = "artifacts/init-job.zip"
    destination = "/home/yc-practitioner/init-job.zip"
    connection {
      type        = "ssh"
      user        = var.username
      private_key = file("~/.ssh/yc.key")
      host        = yandex_compute_instance.db.network_interface.0.ip_address

      bastion_host        = yandex_compute_instance.server.network_interface.0.nat_ip_address
      bastion_user        = var.username
      bastion_private_key = file("~/.ssh/yc.key")
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cp -rp /home/yc-practitioner/redis.conf /etc/redis/redis.conf",
      "sudo systemctl restart redis-server",
      "echo 'redis-server is ready'",
      "echo 'Start init-job'",
      "unzip init-job.zip",
      "pip3 install -r init-job/requirements.txt",
      "python3 init-job/init-job.py"
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
}

output "internal_ip_address_db" {
  value = yandex_compute_instance.db.network_interface.0.ip_address
}
