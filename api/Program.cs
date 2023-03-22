using Microsoft.Identity.Web;
using Microsoft.AspNetCore.Authentication.OpenIdConnect;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddAuthentication(OpenIdConnectDefaults.AuthenticationScheme)
                .AddMicrosoftIdentityWebApp(builder.Configuration.GetSection("AzureAd"))
                    .EnableTokenAcquisitionToCallDownstreamApi()
                        .AddMicrosoftGraph(builder.Configuration.GetSection("Graph"))
                        .AddInMemoryTokenCaches();

// uncomment the following 3 lines to get ClientSecret from KeyVault
//string tenantId = Configuration.GetValue<string>("AzureAd:TenantId");
//services.Configure<MicrosoftIdentityOptions>(
//   options => { options.ClientSecret = GetSecretFromKeyVault(tenantId, "ENTER_YOUR_SECRET_NAME_HERE"); });

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// HealthChecks
builder.Services.AddHealthChecks();

var app = builder.Build();

// HealthChecks
app.MapHealthChecks("/healthz");

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
  app.UseSwagger();
  app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();


// private string GetSecretFromKeyVault(string tenantId, string secretName)
// {
//     // this should point to your vault's URI, like https://<yourkeyvault>.vault.azure.net/
//     string uri = Environment.GetEnvironmentVariable("KEY_VAULT_URI");
//     DefaultAzureCredentialOptions options = new DefaultAzureCredentialOptions();

//     // Specify the tenant ID to use the dev credentials when running the app locally
//     options.VisualStudioTenantId = tenantId;
//     options.SharedTokenCacheTenantId = tenantId;
//     SecretClient client = new SecretClient(new Uri(uri), new DefaultAzureCredential(options));

//     // The secret name, for example if the full url to the secret is https://<yourkeyvault>.vault.azure.net/secrets/ENTER_YOUR_SECRET_NAME_HERE
//     Response<KeyVaultSecret> secret = client.GetSecretAsync(secretName).Result;

//     return secret.Value.Value;
// }