variable "location" {
  type    = string
  default = "eastus2"
}

# variable "aad_domain" {
#   type = string
# }

variable "app_sku_name" {
  type    = string
  default = "B1"
}

variable "app_worker_count" {
  type    = number
  default = 1
}
