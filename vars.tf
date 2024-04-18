locals {
  author             = "Daniil Molkov"
  common_description = "Prepared by ${local.author}" # possible to use a local in a local
}

variable "zone" {
  type    = string
  default = "ru-central1-a"
}

variable "username" {
  type    = string
  default = "yc-practitioner"

}
