terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.48.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.36.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azuread" {}


### Variables ###

resource "random_id" "app_affix" {
  byte_length = 8
}

locals {
  app_name       = "myprivateapp${lower(random_id.app_affix.hex)}"
  app_url        = "https://${local.app_name}.azurewebsites.net"
  identifier_uri = "api://${local.app_name}"
}


### Group ###

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.app_name}"
  location = var.location
}


### Authentication ###

data "azuread_client_config" "current" {}

resource "azuread_user" "main" {
  user_principal_name = var.user_principal
  display_name        = var.user_display_name
  password            = var.user_password
}

data "azuread_application_published_app_ids" "well_known" {}

resource "azuread_service_principal" "msgraph" {
  application_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
  use_existing   = true
}

resource "random_uuid" "oauth2_permission_scope" {}

resource "azuread_application" "app" {
  display_name     = "app-${local.app_name}"
  identifier_uris  = [local.identifier_uri]
  sign_in_audience = "AzureADMyOrg"
  owners           = [data.azuread_client_config.current.object_id]

  web {
    homepage_url  = local.app_url
    redirect_uris = ["${local.app_url}/.auth/login/aad/callback"]

    implicit_grant {
      id_token_issuance_enabled = true
    }
  }

  api {
    requested_access_token_version = 2

    oauth2_permission_scope {
      id                         = random_uuid.oauth2_permission_scope.result
      enabled                    = true
      type                       = "User"
      admin_consent_display_name = "Access File Upload"
      admin_consent_description  = "Allow the application to access File Upload on behalf of the signed-in user."
      user_consent_display_name  = "Access File Upload"
      user_consent_description   = "Allow the application to access File Upload on your behalf."
      value                      = "user_impersonation"
    }
  }

  required_resource_access {
    resource_app_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph

    resource_access {
      id   = azuread_service_principal.msgraph.oauth2_permission_scope_ids["User.Read"]
      type = "Scope"
    }
  }
}

resource "azuread_service_principal" "app" {
  application_id               = azuread_application.app.application_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
  feature_tags {
    enterprise = true
  }
}

resource "azuread_application_password" "app" {
  application_object_id = azuread_application.app.object_id
}

### Log Analytics ###

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${local.app_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

### Application Insights ###

resource "azurerm_application_insights" "app" {
  name                = "appi-${local.app_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
}

### App Services ###

resource "azurerm_service_plan" "main" {
  name                = "plan-${local.app_name}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = var.app_sku_name
  worker_count        = var.app_worker_count
}

resource "azurerm_linux_web_app" "main" {
  name                = local.app_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_service_plan.main.location
  service_plan_id     = azurerm_service_plan.main.id
  https_only          = true

  auth_settings_v2 {
    auth_enabled           = true
    require_authentication = false
    unauthenticated_action = "RedirectToLoginPage"
    default_provider       = "azureactivedirectory"

    login {
      token_store_enabled = true
    }

    active_directory_v2 {
      client_id                  = azuread_application.app.application_id
      tenant_auth_endpoint       = "https://sts.windows.net/${data.azuread_client_config.current.tenant_id}/v2.0"
      client_secret_setting_name = "APP_REGISTRATION_SECRET"
      allowed_audiences          = [local.identifier_uri]

      # This configuration is required as per documentation to integrate package Microsoft.Identity.Web with Graph
      # https://learn.microsoft.com/en-us/azure/app-service/scenario-secure-app-access-microsoft-graph-as-user?tabs=azure-resource-explorer
      login_parameters = [
        "response_type=code id_token",
        "scope=openid offline_access profile https://graph.microsoft.com/User.Read"
      ]
    }
  }

  site_config {
    always_on = true

    application_stack {
      docker_image     = "nginx"
      docker_image_tag = "latest"
    }
  }

  app_settings = {
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.app.connection_string
    DOCKER_REGISTRY_SERVER_URL            = "https://index.docker.io/v1"
    APP_REGISTRATION_SECRET               = azuread_application_password.app.value
  }

  lifecycle {
    ignore_changes = [
      # FIXME: Provider keeps trying to set it to "false". Remove this ignore when the provider is fixed.
      auth_settings_v2[0].login[0].token_store_enabled
    ]
  }
}

resource "azurerm_monitor_diagnostic_setting" "app" {
  name                       = "Application Diagnostics"
  target_resource_id         = azurerm_linux_web_app.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "AppServiceHTTPLogs"

    retention_policy {
      days    = 7
      enabled = true
    }
  }

  enabled_log {
    category = "AppServiceConsoleLogs"

    retention_policy {
      days    = 7
      enabled = true
    }
  }

  enabled_log {
    category = "AppServiceAppLogs"

    retention_policy {
      days    = 7
      enabled = true
    }
  }

  enabled_log {
    category = "AppServiceAuditLogs"

    retention_policy {
      days    = 7
      enabled = true
    }
  }

  enabled_log {
    category = "AppServiceIPSecAuditLogs"

    retention_policy {
      days    = 7
      enabled = true
    }
  }

  enabled_log {
    category = "AppServicePlatformLogs"

    retention_policy {
      days    = 7
      enabled = true
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      days    = 7
      enabled = true
    }
  }
}
