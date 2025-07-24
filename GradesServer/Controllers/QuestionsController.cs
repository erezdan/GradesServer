using Microsoft.AspNetCore.Mvc;

namespace GradesServer.Controllers
{
    public class QuestionsController : Controller
    {
        public IActionResult Index()
        {
            return View();
        }
    }
}
