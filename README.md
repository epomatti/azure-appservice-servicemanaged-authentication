# App Services + AAD Service Managed Authentication

Demonstration of App Service [built-in authentication](https://learn.microsoft.com/en-us/azure/app-service/overview-authentication-authorization) feature.

```sh
cd infrastructure

terraform init
terraform apply -auto-approve
```

> **⚠️ As of the creation of this code, the Terraform Azurerm provider has issues with App Service authentication via `authsettingsV2`. Check [this issue](https://github.com/hashicorp/terraform-provider-azurerm/issues/20913) to apply the appropriate fixes or to follow-up on the solution.**

For that reason, connect to the Portal and create the AAD authentication manually via the `Authentication` blade in your App Service.

Retrict access option should be: **`Require authentication`** with **`HTTP 302 Found redirect`**.

Also, create a user and security groups associated.

Now update App Services to forwardt he required login parameters to the application.

```sh
az rest --method GET --url '/subscriptions/{SUBSCRIPTION_ID}/resourceGroups/{RESOURCE_GROUP}/providers/Microsoft.Web/sites/{WEBAPP_NAME}/config/authsettingsv2/list?api-version=2022-03-01' > authsettings.json
```

Add the `"loginParameters"` section:

```json
"identityProviders": {
    "azureActiveDirectory": {
      "enabled": true,
      "login": {
        "loginParameters":[
          "response_type=code id_token",
          "scope=openid offline_access profile https://graph.microsoft.com/User.Read"
        ]
      }
    }
  }
},
```

Add the `"excludedPaths"` section:

```json
"globalValidation": {
  "excludedPaths": [
    "/api/dogs",
    "/healthz"
  ]
}
```
Update the new configuration:

```sh
az rest --method PUT --url '/subscriptions/{SUBSCRIPTION_ID}/resourceGroups/{RESOURCE_GROUP}/providers/Microsoft.Web/sites/{WEBAPP_NAME}/config/authsettingsv2?api-version=2022-03-01' --body @./authsettings.json
```

Enter the application directory and deploy the application:

```
cd api

bash build.sh

az webapp deployment source config-zip -g rg-myprivateapp826cbe9f966915e2 -n myprivateapp826cbe9f966915e2 --src ./bin/api.zip
```

The following URI paths are available as `GET` controllers:

```
/api/dogs
/api/claims
/api/healthz
```

For debugging, the `/.auth/me` is available.

## Local Development

Create an application registration. No secrets are required for this demonstration.

Add a redirect URL of type Web for `http://localhost:5269`.

Add the environment variables:

docker build -t epomatti/dotnet-easyauth-api .

https://github.com/AzureAD/microsoft-identity-web/wiki/Deploying-Web-apps-to-App-services-as-Linux-containers

```sh
export AzureAd__Domain="<DOMAIN>"
export AzureAd__TenantId="<TENANT_ID>"
export AzureAd__ClientId="<CLIENT_ID>"

export AzureAd__Domain="evandropomattigmail.onmicrosoft.com"
export AzureAd__TenantId="94d47d96-52c0-4b73-b3ae-028fafc55d47"
export AzureAd__ClientId="21e2f69b-7276-46a4-b9a1-42dab27a42cc"
```

https://learn.microsoft.com/en-us/azure/active-directory/develop/scenario-web-api-call-api-overview
https://stackoverflow.com/questions/69001458/asp-net-core-5-webapi-azure-ad-call-graph-api-using-azure-ad-access-token
https://www.youtube.com/watch?v=pcWdR0LcNaI
https://stackoverflow.com/questions/66530370/how-to-use-di-with-microsoft-graph
https://learn.microsoft.com/en-us/azure/app-service/tutorial-auth-aad?pivots=platform-linux#call-api-securely-from-server-code

## References

- [App Services Authentication and Authorization](https://learn.microsoft.com/en-us/azure/app-service/overview-authentication-authorization)
- [Restricting App to a set of users](https://learn.microsoft.com/en-us/azure/active-directory/develop/howto-restrict-your-app-to-a-set-of-users)
- [Customize sign-in/outs](https://learn.microsoft.com/en-us/azure/app-service/configure-authentication-customize-sign-in-out)
- [Access User Identities](https://learn.microsoft.com/en-us/azure/app-service/configure-authentication-user-identities)
- [Microsoft.Identity.Web](https://github.com/AzureAD/microsoft-identity-web/wiki/1.2.0#integration-with-azure-app-services-authentication-of-web-apps-running-with-microsoftidentityweb)
- [App Service -> Key Vault references](https://learn.microsoft.com/en-us/azure/app-service/app-service-key-vault-references?tabs=azure-cli)
