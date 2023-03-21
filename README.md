# App Services + AAD Service Managed Authentication

Demonstration of App Service [built-in authentication](https://learn.microsoft.com/en-us/azure/app-service/overview-authentication-authorization).

```sh
terraform init
terraform apply -auto-approve
```

> **⚠️ As of the creation of this code, the Terraform Azurerm provider has issues related to the authentication feature. Check [this issue](https://github.com/hashicorp/terraform-provider-azurerm/issues/20913) to apply the appropriate fixes or to follow-up on the solution.**

## Local Development

Create an application registration. No secrets are required for this demonstration.

Add a redirect URL of type Web for `http://localhost:5269`.

Add the environment variables:

docker build -t epomatti/dotnet-easyauth-api .


## References

- [App Services Authentication and Authorization](https://learn.microsoft.com/en-us/azure/app-service/overview-authentication-authorization)
- [Restricting App to a set of users](https://learn.microsoft.com/en-us/azure/active-directory/develop/howto-restrict-your-app-to-a-set-of-users)
- [Customize sign-in/outs](https://learn.microsoft.com/en-us/azure/app-service/configure-authentication-customize-sign-in-out)
- [Access User Identities](https://learn.microsoft.com/en-us/azure/app-service/configure-authentication-user-identities)
- [Microsoft.Identity.Web](https://github.com/AzureAD/microsoft-identity-web/wiki/1.2.0#integration-with-azure-app-services-authentication-of-web-apps-running-with-microsoftidentityweb)
- [App Service -> Key Vault references](https://learn.microsoft.com/en-us/azure/app-service/app-service-key-vault-references?tabs=azure-cli)
