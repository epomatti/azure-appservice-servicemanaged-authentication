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

  # feature_tags {
  #   enterprise = true
  # }
}

resource "azuread_application_password" "app" {
  application_object_id = azuread_application.app.object_id

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
  name                = "app-${local.app_name}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_service_plan.main.location
  service_plan_id     = azurerm_service_plan.main.id
  https_only          = true

  auth_settings_v2 {
    auth_enabled           = true
    require_authentication = true
    unauthenticated_action = "RedirectToLoginPage" # RedirectToLoginPage
    default_provider       = "BuiltInAuthenticationProviderAzureActiveDirectory"

    # Required for AFD due to the "X-Forwarded-Host" header
    # forward_proxy_convention = "Standard"

    login {
      token_store_enabled = true
    }

    active_directory_v2 {
      client_id = azuread_application.app.application_id
      # tenant_auth_endpoint       = "https://login.microsoftonline.com/v2.0/${data.azuread_client_config.current.tenant_id}/"
      tenant_auth_endpoint       = "https://sts.windows.net/${data.azuread_client_config.current.tenant_id}/v2.0"
      client_secret_setting_name = "APP_REGISTRATION_SECRET"
      allowed_audiences          = [local.identifier_uri]
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
    DOCKER_REGISTRY_SERVER_URL = "https://index.docker.io/v1"
    APP_REGISTRATION_SECRET    = azuread_application_password.app.value
  }
}
