using Microsoft.AspNetCore.Mvc;
using Microsoft.Graph;
using Microsoft.Identity.Web;

namespace api.Controllers;

[ApiController]
[Route("/api/[controller]")]
[AuthorizeForScopes(Scopes = new[] { "user.read" })]
public class GraphController : ControllerBase
{
  private readonly ILogger<GraphController> _logger;
  private readonly GraphServiceClient _graphServiceClient;

  public GraphController(ILogger<GraphController> logger, GraphServiceClient graphServiceClient)
  {
    _logger = logger;
    _graphServiceClient = graphServiceClient;
  }

  [HttpGet(Name = "GetGraph")]
  public async Task<GraphResponse> Get()
  {
    var user = await _graphServiceClient.Me.Request().GetAsync();
    var response = new GraphResponse
    {
      Name = User.GetDisplayName()
    };
    return response;
  }
}
