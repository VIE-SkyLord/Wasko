using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Wasko.Data;
using Wasko.Models;

namespace Wasko.Controllers
{
    //[Authorize(Roles = "Giảng viên")]
    public class CourseController : Controller
    {
        private readonly ApplicationDbContext _context;

        public CourseController(ApplicationDbContext context)
        {
            _context = context;
        }

        public IActionResult InstructorCourseList()
        {
            return View();
        }
    }
}