using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// Cập nhật cấu hình Identity với thêm các tùy chọn
builder.Services.AddIdentity<ApplicationUser, IdentityRole>(options => 
{
    // Thiết lập cho mật khẩu
    options.Password.RequireDigit = true;
    options.Password.RequiredLength = 6;
    options.Password.RequireNonAlphanumeric = true;
    options.Password.RequireUppercase = true;
    options.Password.RequireLowercase = true;
    
    // Thiết lập cho đăng nhập
    options.SignIn.RequireConfirmedEmail = false; // Đặt true nếu muốn xác nhận email
    options.SignIn.RequireConfirmedPhoneNumber = false;
    
    // Thiết lập cho tài khoản bị khóa
    options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(30);
    options.Lockout.MaxFailedAccessAttempts = 5;
})
.AddEntityFrameworkStores<ApplicationDbContext>()
.AddDefaultTokenProviders();

// Cập nhật thiết lập cookie với nhiều options hơn
builder.Services.ConfigureApplicationCookie(options =>
{
    options.LoginPath = "/Account/Login";
    options.AccessDeniedPath = "/Account/AccessDenied";
    options.ExpireTimeSpan = TimeSpan.FromDays(14); // Thời gian cookie hết hạn
    options.SlidingExpiration = true; // Làm mới thời gian khi người dùng hoạt động
    options.Cookie.HttpOnly = true; // Bảo mật hơn, không cho phép JavaScript truy cập
});

builder.Services.AddControllersWithViews();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}
else
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();

app.UseAuthentication();
app.UseAuthorization();
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();