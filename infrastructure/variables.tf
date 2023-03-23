variable "location" {
  type    = string
  default = "eastus2"
}

variable "app_sku_name" {
  type    = string
  default = "B1"
}

variable "app_worker_count" {
  type    = number
  default = 1
}

variable "require_authentication" {
  type    = bool
  default = true
}

variable "unauthenticated_client_action" {
  type    = string
  default = "RedirectToLoginPage" # For API, use Return401
}
