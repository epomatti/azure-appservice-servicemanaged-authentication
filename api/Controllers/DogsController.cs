using Microsoft.AspNetCore.Mvc;

namespace api.Controllers;

[ApiController]
[Route("/api/[controller]")]
public class DogsController : ControllerBase
{
  private readonly ILogger<DogsController> _logger;

  public DogsController(ILogger<DogsController> logger)
  {
    _logger = logger;
  }

  [HttpGet(Name = "GetDogs")]
  public DogsResponse Get()
  {
    return new DogsResponse
    {
      Dog = "Woof!"
    };
  }
}
