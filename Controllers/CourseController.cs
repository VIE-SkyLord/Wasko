using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using Wasko.Data;
using Wasko.Models;

namespace Wasko.Controllers
{
    [Authorize(Roles = "Giảng viên")]
    public class CourseController : Controller
    {
        private readonly ApplicationDbContext _context;

        public CourseController(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<IActionResult> InstructorCourseList()
        {
            // Get current logged in instructor ID
            var instructorId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            
            // Get courses for the instructor with related entities
            var courses = await _context.KhoaHoc
                .Include(k => k.ChuDe)
                .Where(k => k.IdGiangVien == instructorId)
                .OrderByDescending(k => k.NgayTao)
                .ToListAsync();
            
            // Get list of topics for dropdown
            var topics = await _context.ChuDe.OrderBy(c => c.TenChuDe).ToListAsync();
            
            ViewBag.Topics = topics;
            
            return View(courses);
        }
        
        [HttpGet]
        public async Task<IActionResult> GetCourses(string keyword, string status, int? topicId)
        {
            var instructorId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            
            var query = _context.KhoaHoc
                .Include(k => k.ChuDe)
                .Where(k => k.IdGiangVien == instructorId);
            
            // Apply filters
            if (!string.IsNullOrEmpty(keyword))
            {
                query = query.Where(k => k.TenKhoaHoc.Contains(keyword));
            }
            
            if (!string.IsNullOrEmpty(status))
            {
                query = query.Where(k => k.TrangThai == status);
            }
            
            if (topicId.HasValue && topicId > 0)
            {
                query = query.Where(k => k.IdChuDe == topicId);
            }
            
            var courses = await query
                .OrderByDescending(k => k.NgayTao)
                .ToListAsync();
                
            return Json(courses);
        }
        
        [HttpGet]
        public async Task<IActionResult> GetTopics()
        {
            var topics = await _context.ChuDe.OrderBy(c => c.TenChuDe).ToListAsync();
            return Json(topics);
        }
        
        [HttpPost]
        public async Task<IActionResult> CreateCourse(KhoaHoc model)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }
            
            try
            {
                // Set default values
                model.IdGiangVien = User.FindFirstValue(ClaimTypes.NameIdentifier);
                model.TrangThai = "Chưa xuất bản";
                model.NgayTao = DateTime.Now;
                
                await _context.KhoaHoc.AddAsync(model);
                await _context.SaveChangesAsync();
                
                return Json(new { success = true, id = model.IdKhoaHoc });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = ex.Message });
            }
        }
        
        [HttpPut]
        public async Task<IActionResult> SubmitForReview(int id)
        {
            var course = await _context.KhoaHoc.FindAsync(id);
            
            if (course == null)
            {
                return NotFound();
            }
            
            if (course.IdGiangVien != User.FindFirstValue(ClaimTypes.NameIdentifier))
            {
                return Forbid();
            }
            
            course.TrangThai = "Đang chờ duyệt";
            
            await _context.SaveChangesAsync();
            
            return Ok();
        }
        
        [HttpPut]
        public async Task<IActionResult> CancelSubmit(int id)
        {
            var course = await _context.KhoaHoc.FindAsync(id);
            
            if (course == null)
            {
                return NotFound();
            }
            
            if (course.IdGiangVien != User.FindFirstValue(ClaimTypes.NameIdentifier))
            {
                return Forbid();
            }
            
            course.TrangThai = "Chưa xuất bản";
            
            await _context.SaveChangesAsync();
            
            return Ok();
        }
        
        [HttpPut]
        public async Task<IActionResult> RecallCourse(int id, string reason)
        {
            var course = await _context.KhoaHoc.FindAsync(id);
            
            if (course == null)
            {
                return NotFound();
            }
            
            if (course.IdGiangVien != User.FindFirstValue(ClaimTypes.NameIdentifier))
            {
                return Forbid();
            }
            
            course.TrangThai = "Đã thu hồi";
            // Store the reason in a note or log if needed
            
            await _context.SaveChangesAsync();
            
            return Ok();
        }
        
        [HttpPost]
        public async Task<IActionResult> CloneCourse(int id)
        {
            var originalCourse = await _context.KhoaHoc
                .Include(k => k.DanhSachBaiHoc)
                    .ThenInclude(b => b.DanhSachTaiLieu)
                .Include(k => k.DanhSachBaiHoc)
                    .ThenInclude(b => b.BaiKiemTra)
                        .ThenInclude(bt => bt.DanhSachCauHoi)
                            .ThenInclude(ch => ch.DanhSachPhuongAn)
                .FirstOrDefaultAsync(k => k.IdKhoaHoc == id);
            
            if (originalCourse == null)
            {
                return NotFound();
            }
            
            if (originalCourse.IdGiangVien != User.FindFirstValue(ClaimTypes.NameIdentifier))
            {
                return Forbid();
            }
            
            // Create new course
            var newCourse = new KhoaHoc
            {
                IdBanGoc = originalCourse.IdKhoaHoc,
                IdGiangVien = originalCourse.IdGiangVien,
                TenKhoaHoc = $"{originalCourse.TenKhoaHoc} (Bản sao)",
                TrangThai = "Chưa xuất bản",
                MoTa = originalCourse.MoTa,
                NgayTao = DateTime.Now,
                IdChuDe = originalCourse.IdChuDe,
                CapDo = originalCourse.CapDo,
                GiaKhoaHoc = originalCourse.GiaKhoaHoc
            };
            
            await _context.KhoaHoc.AddAsync(newCourse);
            await _context.SaveChangesAsync();
            
            // Clone lessons and materials
            if (originalCourse.DanhSachBaiHoc != null)
            {
                foreach (var origLesson in originalCourse.DanhSachBaiHoc)
                {
                    var newLesson = new BaiHoc
                    {
                        IdKhoaHoc = newCourse.IdKhoaHoc,
                        TenBaiHoc = origLesson.TenBaiHoc,
                        MoTa = origLesson.MoTa
                    };
                    
                    await _context.BaiHoc.AddAsync(newLesson);
                    await _context.SaveChangesAsync();
                    
                    // Clone materials
                    if (origLesson.DanhSachTaiLieu != null)
                    {
                        foreach (var origMaterial in origLesson.DanhSachTaiLieu)
                        {
                            var newMaterial = new TaiLieuHocTap
                            {
                                IdBaiHoc = newLesson.IdBaiHoc,
                                LoaiTaiLieu = origMaterial.LoaiTaiLieu,
                                URL = origMaterial.URL
                            };
                            
                            await _context.TaiLieuHocTap.AddAsync(newMaterial);
                        }
                    }
                    
                    // Clone tests
                    if (origLesson.BaiKiemTra != null)
                    {
                        var origTest = origLesson.BaiKiemTra;
                        
                        var newTest = new BaiKiemTra
                        {
                            IdBaiHoc = newLesson.IdBaiHoc,
                            PhanTramDat = origTest.PhanTramDat
                        };
                        
                        await _context.BaiKiemTra.AddAsync(newTest);
                        await _context.SaveChangesAsync();
                        
                        // Clone questions
                        if (origTest.DanhSachCauHoi != null)
                        {
                            foreach (var origQuestion in origTest.DanhSachCauHoi)
                            {
                                var newQuestion = new CauHoiTracNghiem
                                {
                                    IdBaiKiemTra = newTest.IdBaiKiemTra,
                                    NoiDungCauHoi = origQuestion.NoiDungCauHoi,
                                    IdDapAn = origQuestion.IdDapAn,
                                    DiemCauHoi = origQuestion.DiemCauHoi
                                };
                                
                                await _context.CauHoiTracNghiem.AddAsync(newQuestion);
                                await _context.SaveChangesAsync();
                                
                                // Clone options
                                if (origQuestion.DanhSachPhuongAn != null)
                                {
                                    foreach (var origOption in origQuestion.DanhSachPhuongAn)
                                    {
                                        var newOption = new PhuongAn
                                        {
                                            IdCauHoi = newQuestion.IdCauHoi,
                                            NoiDungPhuongAn = origOption.NoiDungPhuongAn
                                        };
                                        
                                        await _context.PhuongAn.AddAsync(newOption);
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            await _context.SaveChangesAsync();
            
            return Json(new { success = true, id = newCourse.IdKhoaHoc });
        }
        
        [HttpDelete]
        public async Task<IActionResult> DeleteCourse(int id)
        {
            var course = await _context.KhoaHoc.FindAsync(id);
            
            if (course == null)
            {
                return NotFound();
            }
            
            if (course.IdGiangVien != User.FindFirstValue(ClaimTypes.NameIdentifier))
            {
                return Forbid();
            }
            
            // Only allow deletion of unpublished courses
            if (course.TrangThai != "Chưa xuất bản")
            {
                return BadRequest("Chỉ có thể xóa khóa học chưa xuất bản");
            }
            
            _context.KhoaHoc.Remove(course);
            await _context.SaveChangesAsync();
            
            return Ok();
        }
        
        [HttpGet]
        public async Task<IActionResult> CourseDetails(int id)
        {
            var course = await _context.KhoaHoc
                .Include(k => k.ChuDe)
                .Include(k => k.GiangVien)
                .Include(k => k.DanhSachBaiHoc)
                    .ThenInclude(b => b.DanhSachTaiLieu)
                .Include(k => k.DanhSachBaiHoc)
                    .ThenInclude(b => b.BaiKiemTra)
                .FirstOrDefaultAsync(k => k.IdKhoaHoc == id);
                
            if (course == null)
            {
                return NotFound();
            }
            
            if (course.IdGiangVien != User.FindFirstValue(ClaimTypes.NameIdentifier))
            {
                return Forbid();
            }
            
            return View(course);
        }
        
        [HttpGet]
        public async Task<IActionResult> EditCourse(int id)
        {
            var course = await _context.KhoaHoc.FindAsync(id);
            
            if (course == null)
            {
                return NotFound();
            }
            
            if (course.IdGiangVien != User.FindFirstValue(ClaimTypes.NameIdentifier))
            {
                return Forbid();
            }
            
            // Only allow editing of unpublished or recalled courses
            if (course.TrangThai != "Chưa xuất bản" && course.TrangThai != "Đã thu hồi")
            {
                return RedirectToAction(nameof(InstructorCourseList));
            }
            
            ViewBag.Topics = await _context.ChuDe.OrderBy(c => c.TenChuDe).ToListAsync();
            
            return View(course);
        }
        
        [HttpPost]
        public async Task<IActionResult> UpdateCourse(KhoaHoc model)
        {
            if (!ModelState.IsValid)
            {
                ViewBag.Topics = await _context.ChuDe.OrderBy(c => c.TenChuDe).ToListAsync();
                return View("EditCourse", model);
            }
            
            var course = await _context.KhoaHoc.FindAsync(model.IdKhoaHoc);
            
            if (course == null)
            {
                return NotFound();
            }
            
            if (course.IdGiangVien != User.FindFirstValue(ClaimTypes.NameIdentifier))
            {
                return Forbid();
            }
            
            // Only allow editing of unpublished or recalled courses
            if (course.TrangThai != "Chưa xuất bản" && course.TrangThai != "Đã thu hồi")
            {
                return BadRequest("Không thể chỉnh sửa khóa học trong trạng thái này");
            }
            
            // Update properties
            course.TenKhoaHoc = model.TenKhoaHoc;
            course.MoTa = model.MoTa;
            course.IdChuDe = model.IdChuDe;
            course.CapDo = model.CapDo;
            course.GiaKhoaHoc = model.GiaKhoaHoc;
            
            await _context.SaveChangesAsync();
            
            return RedirectToAction(nameof(CourseDetails), new { id = course.IdKhoaHoc });
        }
    }
}