terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
    archive = {
      source = "hashicorp/archive"
    }
  }
  required_version = ">0.13"
}

provider "yandex" {
  zone  = var.zone
  alias = "central"
}
