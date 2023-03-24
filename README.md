# App Services + AAD Service Managed Authentication

Demonstration of App Service [built-in authentication](https://learn.microsoft.com/en-us/azure/app-service/overview-authentication-authorization) feature.

## Running on Azure

```sh
cd infrastructure

terraform init
terraform apply -auto-approve
```

`cd api` into the API directory and deploy the application:

```
bash build.sh
az webapp deployment source config-zip -g <group> -n <app> --src ./bin/api.zip
```

Test the application. The following URI paths are available as `GET` controllers:

```
/api/dogs
/api/claims
/api/healthz

# This is bugged due to SDK issue
/api/graph
```

For debugging, the `/.auth/me` is available.

## Local Development

Create an application registration using the portal or cli. No secrets are required for this demonstration. Add a redirect URL of type Web for `http://localhost:5269/.auth/login/aad/callback`.

Add the environment variables:

```sh
export AzureAd__Domain="<DOMAIN>"
export AzureAd__TenantId="<TENANT_ID>"
export AzureAd__ClientId="<CLIENT_ID>"
```

Run the application:

```
dotnet restore
dotnet run
```

## References

- [App Services Authentication and Authorization](https://learn.microsoft.com/en-us/azure/app-service/overview-authentication-authorization)
- [Restricting App to a set of users](https://learn.microsoft.com/en-us/azure/active-directory/develop/howto-restrict-your-app-to-a-set-of-users)
- [Customize sign-in/outs](https://learn.microsoft.com/en-us/azure/app-service/configure-authentication-customize-sign-in-out)
- [Access User Identities](https://learn.microsoft.com/en-us/azure/app-service/configure-authentication-user-identities)
- [Microsoft.Identity.Web](https://github.com/AzureAD/microsoft-identity-web/wiki/1.2.0#integration-with-azure-app-services-authentication-of-web-apps-running-with-microsoftidentityweb)
- [App Service -> Key Vault references](https://learn.microsoft.com/en-us/azure/app-service/app-service-key-vault-references?tabs=azure-cli)

Other sources:

```
https://learn.microsoft.com/en-us/azure/active-directory/develop/scenario-web-api-call-api-overview
https://stackoverflow.com/questions/69001458/asp-net-core-5-webapi-azure-ad-call-graph-api-using-azure-ad-access-token
https://www.youtube.com/watch?v=pcWdR0LcNaI
https://stackoverflow.com/questions/66530370/how-to-use-di-with-microsoft-graph
https://learn.microsoft.com/en-us/azure/app-service/tutorial-auth-aad?pivots=platform-linux#call-api-securely-from-server-code
```
