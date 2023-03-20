variable "location" {
  type    = string
  default = "eastus2"
}

variable "sys" {
  type    = string
  default = "myprivateapp"
}

variable "app_sku_name" {
  type    = string
  default = "B2"
}

variable "app_worker_count" {
  type    = number
  default = 1
}
