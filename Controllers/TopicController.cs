using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Wasko.Data;
using Wasko.Models;
using System;
using System.Threading.Tasks;

[Authorize(Roles = "Quản trị viên")]
public class TopicController  : Controller
{
    private readonly ApplicationDbContext _context;

    public TopicController (ApplicationDbContext context)
    {
        _context = context;
    }

    // GET: ChuDe - List all topics
    public async Task<IActionResult> Index()
    {
        return View(await _context.ChuDe.ToListAsync());
    }

    // GET: ChuDe/Details/5
    public async Task<IActionResult> Details(int? id)
    {
        if (id == null)
            return NotFound();

        var chuDe = await _context.ChuDe
            .FirstOrDefaultAsync(m => m.Id == id);
        if (chuDe == null)
            return NotFound();

        return View(chuDe);
    }

    // GET: ChuDe/Create
    public IActionResult Create()
    {
        return View();
    }

    // POST: ChuDe/Create
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create([Bind("TenChuDe")] ChuDe chuDe)
    {
        if (ModelState.IsValid)
        {
            _context.Add(chuDe);
            
            // Thông báo cho giảng viên về chủ đề mới
            var thongBao = new ThongBao
            {
                NoiDung = $"Chủ đề mới \"{chuDe.TenChuDe}\" đã được tạo bởi quản trị viên.",
                ThoiGian = DateTime.Now,
                NguoiNhanRole = "Giảng viên"
            };
            _context.ThongBao.Add(thongBao);
            
            await _context.SaveChangesAsync();
            TempData["SuccessMessage"] = $"Chủ đề '{chuDe.TenChuDe}' đã được tạo thành công!";
            return RedirectToAction(nameof(Index));
        }
        return View(chuDe);
    }

    // GET: ChuDe/Edit/5
    public async Task<IActionResult> Edit(int? id)
    {
        if (id == null)
            return NotFound();

        var chuDe = await _context.ChuDe.FindAsync(id);
        if (chuDe == null)
            return NotFound();

        return View(chuDe);
    }

    // POST: ChuDe/Edit/5
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(int id, [Bind("Id,TenChuDe")] ChuDe chuDe)
    {
        if (id != chuDe.Id)
            return NotFound();

        if (ModelState.IsValid)
        {
            try
            {
                _context.Update(chuDe);

                // Gửi thông báo đến giảng viên
                var thongBao = new ThongBao
                {
                    NoiDung = $"Chủ đề \"{chuDe.TenChuDe}\" đã được chỉnh sửa bởi quản trị viên.",
                    ThoiGian = DateTime.Now,
                    NguoiNhanRole = "Giảng viên"
                };
                _context.ThongBao.Add(thongBao);

                await _context.SaveChangesAsync();
                TempData["SuccessMessage"] = $"Chủ đề '{chuDe.TenChuDe}' đã được cập nhật thành công!";
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!ChuDeExists(chuDe.Id))
                    return NotFound();
                else
                    throw;
            }
            return RedirectToAction(nameof(Index));
        }
        return View(chuDe);
    }

    // GET: ChuDe/Delete/5
    public async Task<IActionResult> Delete(int? id)
    {
        if (id == null)
            return NotFound();

        var chuDe = await _context.ChuDe
            .FirstOrDefaultAsync(m => m.Id == id);
        if (chuDe == null)
            return NotFound();

        return View(chuDe);
    }

    // POST: ChuDe/Delete/5
    [HttpPost, ActionName("Delete")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteConfirmed(int id)
    {
        var chuDe = await _context.ChuDe.FindAsync(id);
        if (chuDe == null)
            return NotFound();
        
        // Lưu tên chủ đề trước khi xóa để sử dụng trong thông báo
        string tenChuDe = chuDe.TenChuDe;
        
        _context.ChuDe.Remove(chuDe);
        
        // Gửi thông báo đến giảng viên
        var thongBao = new ThongBao
        {
            NoiDung = $"Chủ đề \"{tenChuDe}\" đã bị xóa bởi quản trị viên.",
            ThoiGian = DateTime.Now,
            NguoiNhanRole = "Giảng viên"
        };
        _context.ThongBao.Add(thongBao);
        
        await _context.SaveChangesAsync();
        TempData["SuccessMessage"] = $"Chủ đề '{tenChuDe}' đã được xóa thành công!";
        return RedirectToAction(nameof(Index));
    }

    private bool ChuDeExists(int id)
    {
        return _context.ChuDe.Any(e => e.Id == id);
    }
}