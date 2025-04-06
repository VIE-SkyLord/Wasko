using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

// ViewModel để hiển thị danh sách người dùng và vai trò của họ
public class UserRolesViewModel
{
    public string UserId { get; set; }
    public string UserName { get; set; }
    public string Email { get; set; }
    public string PhoneNumber { get; set; }
    public List<string> Roles { get; set; }
}

// ViewModel để quản lý vai trò của một người dùng cụ thể
public class ManageUserRolesViewModel
{
    public string UserId { get; set; }
    public string UserName { get; set; }
    public string Email { get; set; }
    public string PhoneNumber { get; set; } 
    public List<RoleSelection> RolesList { get; set; }
}

// Lớp để lưu trữ thông tin về việc lựa chọn vai trò
public class RoleSelection
{
    public string RoleId { get; set; }
    public string RoleName { get; set; }
    public bool IsSelected { get; set; }
}
