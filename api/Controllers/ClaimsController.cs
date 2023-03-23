using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace api.Controllers;

[Authorize]
[ApiController]
[Route("/api/[controller]")]
public class ClaimsController : ControllerBase
{
  private readonly ILogger<ClaimsController> _logger;

  public ClaimsController(ILogger<ClaimsController> logger)
  {
    _logger = logger;
  }

  [HttpGet(Name = "GetClaims")]
  public ClaimsResponse Get()
  {
    return new ClaimsResponse
    {
      Email = HttpContext.User.FindFirst(ClaimTypes.Email)?.Value,
      Groups = HttpContext.User.FindFirst("groups")?.Value,
      PreferredUsername = HttpContext.User.FindFirst("preferred_username")?.Value,
    };
  }
}
