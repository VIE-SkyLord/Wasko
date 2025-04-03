using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;

[Authorize(Roles = "Quản trị viên")]
public class RoleController : Controller
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly RoleManager<IdentityRole> _roleManager;

    public RoleController(UserManager<ApplicationUser> userManager, RoleManager<IdentityRole> roleManager)
    {
        _userManager = userManager;
        _roleManager = roleManager;
    }

    // Hiển thị danh sách tất cả người dùng và vai trò của họ
    public async Task<IActionResult> Index()
    {
        var users = await _userManager.Users.ToListAsync();
        var userRolesViewModel = new List<UserRolesViewModel>();
        
        foreach (var user in users)
        {
            var roles = await _userManager.GetRolesAsync(user);
            
            userRolesViewModel.Add(new UserRolesViewModel
            {
                UserId = user.Id,
                UserName = user.UserName,
                Email = user.Email,
                PhoneNumber = user.PhoneNumber,
                Roles = roles.ToList()
            });
        }
        
        return View(userRolesViewModel);
    }

    // Hiển thị form quản lý vai trò của một người dùng cụ thể
    public async Task<IActionResult> ManageRoles(string userId)
    {
        var user = await _userManager.FindByIdAsync(userId);
        if (user == null)
        {
            TempData["Error"] = "Không tìm thấy người dùng!";
            return RedirectToAction("Index");
        }

        var userRoles = await _userManager.GetRolesAsync(user);

        var model = new ManageUserRolesViewModel
        {
            UserId = userId,
            UserName = user.UserName,
            Email = user.Email,
            PhoneNumber = user.PhoneNumber,
            RolesList = _roleManager.Roles
                .Where(r => userRoles.Contains(r.Name)) // Lọc chỉ các vai trò hiện tại của người dùng
                .Select(r => new RoleSelection
                {
                    RoleName = r.Name
                })
                .ToList()
        };

        return View(model);
    }


    // Xử lý việc cập nhật vai trò cho người dùng
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UpdateRoles(ManageUserRolesViewModel model)
    {
        var user = await _userManager.FindByIdAsync(model.UserId);
        if (user == null)
        {
            TempData["Error"] = "Không tìm thấy người dùng!";
            return RedirectToAction("Index");
        }

        // Lấy vai trò hiện tại của người dùng
        var userRoles = await _userManager.GetRolesAsync(user);

        // Lọc các vai trò để không cho phép Quản trị viên được thêm hoặc xóa
        var rolesToAdd = model.RolesList
                            .Where(r => r.IsSelected && !userRoles.Contains(r.RoleName) && r.RoleName != "Quản trị viên")
                            .Select(r => r.RoleName)
                            .ToList();

        var rolesToRemove = model.RolesList
                                .Where(r => !r.IsSelected && userRoles.Contains(r.RoleName) && r.RoleName != "Quản trị viên")
                                .Select(r => r.RoleName)
                                .ToList();

        // Thêm các vai trò mới
        foreach (var role in rolesToAdd)
        {
            var result = await _userManager.AddToRoleAsync(user, role);
            if (!result.Succeeded)
            {
                foreach (var error in result.Errors)
                {
                    ModelState.AddModelError("", error.Description);
                }
            }
        }

        // Xóa các vai trò không còn được chọn
        foreach (var role in rolesToRemove)
        {
            var result = await _userManager.RemoveFromRoleAsync(user, role);
            if (!result.Succeeded)
            {
                foreach (var error in result.Errors)
                {
                    ModelState.AddModelError("", error.Description);
                }
            }
        }

        if (!ModelState.IsValid)
        {
            // Nếu có lỗi, quay lại form với dữ liệu và lỗi
            return await ManageRoles(model.UserId);
        }

        TempData["Success"] = "Cập nhật vai trò thành công!";
        return RedirectToAction("Index");
    }
    
    // Nâng cấp vai trò của học viên lên giảng viên
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> PromoteToInstructor(string userId)
    {
        var user = await _userManager.FindByIdAsync(userId);
        if (user == null)
        {
            TempData["Error"] = "Không tìm thấy người dùng!";
            return RedirectToAction("Index");
        }
        
        // Kiểm tra xem người dùng có vai trò học viên không
        if (!await _userManager.IsInRoleAsync(user, "Học viên"))
        {
            TempData["Error"] = "Người dùng không phải là học viên!";
            return RedirectToAction("Index");
        }
        
        // Xóa vai trò học viên và thêm vai trò giảng viên
        await _userManager.RemoveFromRoleAsync(user, "Học viên");
        await _userManager.AddToRoleAsync(user, "Giảng viên");
        
        TempData["Success"] = $"Đã nâng cấp {user.UserName} từ Học viên lên Giảng viên thành công!";
        return RedirectToAction("Index");
    }
    
    // Nâng cấp vai trò lên kiểm duyệt viên
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> PromoteToModerator(string userId)
    {
        var user = await _userManager.FindByIdAsync(userId);
        if (user == null)
        {
            TempData["Error"] = "Không tìm thấy người dùng!";
            return RedirectToAction("Index");
        }
        
        // Thêm vai trò kiểm duyệt viên (không xóa vai trò hiện tại)
        await _userManager.AddToRoleAsync(user, "Kiểm duyệt viên");
        
        TempData["Success"] = $"Đã thêm vai trò Kiểm duyệt viên cho {user.UserName} thành công!";
        return RedirectToAction("Index");
    }
    
    // Quản lý danh sách các vai trò trong hệ thống
    public async Task<IActionResult> RolesList()
    {
        var roles = await _roleManager.Roles.ToListAsync();
        return View(roles);
    }
}
