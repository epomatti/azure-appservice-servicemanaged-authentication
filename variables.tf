variable "location" {
  type    = string
  default = "eastus2"
}

variable "user_principal" {
  type = string
}

variable "user_display_name" {
  type    = string
  default = "Jack"
}

variable "user_password" {
  type    = string
  default = "SecretP@sswd99!"
}

variable "app_sku_name" {
  type    = string
  default = "B2"
}

variable "app_worker_count" {
  type    = number
  default = 1
}
