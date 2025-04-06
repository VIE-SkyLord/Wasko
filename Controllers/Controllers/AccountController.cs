using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Linq;
using System.Threading.Tasks;
using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;

public class AccountController : Controller
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly SignInManager<ApplicationUser> _signInManager;

    public AccountController(UserManager<ApplicationUser> userManager, SignInManager<ApplicationUser> signInManager)
    {
        _userManager = userManager;
        _signInManager = signInManager;
    }

    // Đăng ký
    public IActionResult Register() => View();

    [HttpPost]
    public async Task<IActionResult> Register(RegisterViewModel model)
    {
        if (string.IsNullOrEmpty(model.Email) && string.IsNullOrEmpty(model.PhoneNumber))
        {
            ModelState.AddModelError("", "Cần nhập Email hoặc Số điện thoại.");
            return View(model);
        }

        if (ModelState.IsValid)
        {
            string generatedUserName;
            int attempt = 0;

            // Tạo UserName mới và kiểm tra xem có bị trùng không
            do
            {
                int randomNumber = new Random().Next(0, 999999999); // Số ngẫu nhiên 9 chữ số
                generatedUserName = $"{"User"}{randomNumber}";
                
                if (++attempt > 10)
                {
                    ModelState.AddModelError("", "Lỗi hệ thống: Không thể tạo Username duy nhất.");
                    return View(model);
                }
            }
            while (await _userManager.Users.AnyAsync(u => u.UserName == generatedUserName));

            var user = new ApplicationUser
            {
                UserName = generatedUserName,
                Email = model.Email,
                PhoneNumber = model.PhoneNumber
            };

            var result = await _userManager.CreateAsync(user, model.Password);

            if (result.Succeeded)
            {
                await _userManager.AddToRoleAsync(user, "Học viên");

                // Cập nhật Claims khi đăng nhập
                await SignInWithClaims(user);

                TempData["RegisterSuccess"] = "Chào mừng bạn đến với Wasko! 🎉";
                return RedirectToAction("Index", "Home");
            }

            foreach (var error in result.Errors)
            {
                ModelState.AddModelError("", error.Description);
            }
        }

        return View(model);
    }

    // Đăng nhập
    public IActionResult Login() => View();

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Login(LoginViewModel model)
    {
        if (ModelState.IsValid)
        {
            var user = await _userManager.FindByEmailAsync(model.LoginIdentifier)
                        ?? await _userManager.Users.FirstOrDefaultAsync(u => u.PhoneNumber == model.LoginIdentifier);

            if (user != null && !string.IsNullOrEmpty(user.UserName))
            {
                var result = await _signInManager.PasswordSignInAsync(user.UserName, model.Password, model.RememberMe, false);
                if (result.Succeeded)
                {
                    await SignInWithClaims(user); // Đăng nhập kèm theo Claims (vai trò)

                    TempData["LoginSuccess"] = "Đăng nhập thành công! Chào mừng bạn trở lại! 🎉";
                    return RedirectToAction("Index", "Home");
                }
                else if (result.IsLockedOut)
                {
                    TempData["LoginError"] = "Tài khoản của bạn đã bị khóa! Vui lòng thử lại sau.";
                }
                else if (result.IsNotAllowed)
                {
                    TempData["LoginError"] = "Tài khoản chưa được xác minh!";
                }
                else
                {
                    TempData["LoginError"] = "Sai mật khẩu! Vui lòng kiểm tra lại.";
                }
            }
            else
            {
                TempData["LoginError"] = "Không tìm thấy tài khoản! Vui lòng kiểm tra lại Email/Số điện thoại.";
            }
        }
        else
        {
            TempData["LoginError"] = "Dữ liệu nhập vào không hợp lệ.";
        }

        return View(model);
    }

    // Đăng xuất
    public async Task<IActionResult> Logout()
    {
        await _signInManager.SignOutAsync();
        return RedirectToAction("Index", "Home");
    }

    // Trang thông tin cá nhân (chỉ cho phép người dùng đã đăng nhập)
    [Authorize]
    public async Task<IActionResult> Profile()
    {
        try
        {
            // Lấy Id từ claims thay vì sử dụng GetUserAsync
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId))
            {
                TempData["ErrorMessage"] = "Không tìm thấy thông tin người dùng trong claims.";
                return RedirectToAction("Login");
            }
            
            // Tìm user theo Id
            var user = await _userManager.FindByIdAsync(userId);
            if (user == null)
            {
                TempData["ErrorMessage"] = "Không tìm thấy thông tin người dùng.";
                return RedirectToAction("Login");
            }
            
            var model = new ProfileViewModel
            {
                UserName = user.UserName,
                Email = user.Email,
                PhoneNumber = user.PhoneNumber
            };
            
            return View(model);
        }
        catch (Exception ex)
        {
            // Ghi log lỗi
            System.Diagnostics.Debug.WriteLine($"Error in Profile: {ex.Message}");
            TempData["ErrorMessage"] = "Đã xảy ra lỗi khi tải thông tin người dùng.";
            return RedirectToAction("Login");
        }
    }

    // Cập nhật thông tin cá nhân
    [HttpPost]
    [Authorize]
    public async Task<IActionResult> UpdateProfile(ProfileViewModel model)
    {
        if (!ModelState.IsValid)
        {
            return View("Profile", model);
        }

        var user = await _userManager.GetUserAsync(User);
        if (user == null) return NotFound();

        user.UserName = model.UserName;
        user.Email = model.Email;
        user.PhoneNumber = model.PhoneNumber;

        var result = await _userManager.UpdateAsync(user);
        if (result.Succeeded)
        {
            TempData["SuccessMessage"] = "Cập nhật thông tin thành công!";
        }
        else
        {
            TempData["ErrorMessage"] = "Có lỗi xảy ra khi cập nhật thông tin.";
        }

        return RedirectToAction("Profile");
    }

    // Hàm hỗ trợ đăng nhập với Claims
    private async Task SignInWithClaims(ApplicationUser user)
    {
        // Đảm bảo đăng xuất trước
        await _signInManager.SignOutAsync();
        
        // Lấy tất cả vai trò của người dùng
        var roles = await _userManager.GetRolesAsync(user);
        
        // Tạo danh sách claims
        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id),  // Thêm claim ID - rất quan trọng!
            new Claim(ClaimTypes.Name, user.UserName ?? ""),
            new Claim(ClaimTypes.Email, user.Email ?? "")
        };
        
        // Thêm từng vai trò vào claims
        foreach (var role in roles)
        {
            claims.Add(new Claim(ClaimTypes.Role, role));
        }
        
        // Tạo identity và principal
        var claimsIdentity = new ClaimsIdentity(claims, IdentityConstants.ApplicationScheme);
        var claimsPrincipal = new ClaimsPrincipal(claimsIdentity);
        
        // Thiết lập thêm các tùy chọn đăng nhập nếu cần
        var authProperties = new AuthenticationProperties
        {
            IsPersistent = true, // Cho phép "Remember me"
            ExpiresUtc = DateTimeOffset.UtcNow.AddDays(14) // Cookie hết hạn sau 14 ngày
        };
        
        // Đăng nhập với claims và properties đã thiết lập
        await HttpContext.SignInAsync(
            IdentityConstants.ApplicationScheme,
            claimsPrincipal,
            authProperties);
            
        // Ghi log hoặc debug thông tin nếu cần
        System.Diagnostics.Debug.WriteLine($"User {user.UserName} logged in with roles: {string.Join(", ", roles)}");
    }
    [Authorize]
    public IActionResult ClaimsDebug()
    {
        var claims = User.Claims.Select(c => $"{c.Type}: {c.Value}").ToList();
        return Content(string.Join("\n", claims));
    }
}
