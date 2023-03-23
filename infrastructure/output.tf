data "azurerm_subscription" "current" {
}

locals {
  authsettingsv2_version = "2022-03-01"
  subscription_id        = data.azurerm_subscription.current.subscription_id
}

output "app_default_hostname" {
  value = azurerm_linux_web_app.main.default_hostname
}

output "az_rest_get_authsettingsv2" {
  value = "az rest --method GET --url '/subscriptions/${local.subscription_id}/resourceGroups/${azurerm_resource_group.main.name}/providers/Microsoft.Web/sites/${azurerm_linux_web_app.main.name}/config/authsettingsv2/list?api-version=${local.authsettingsv2_version}' > authsettings.json"
}

output "az_rest_put_authsettingsv2" {
  value = "az rest --method PUT --url '/subscriptions/${local.subscription_id}/resourceGroups/${azurerm_resource_group.main.name}/providers/Microsoft.Web/sites/${azurerm_linux_web_app.main.name}/config/authsettingsv2?api-version=${local.authsettingsv2_version}' --body @./authsettings.json"
}
