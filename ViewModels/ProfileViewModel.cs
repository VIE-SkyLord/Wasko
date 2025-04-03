using System.ComponentModel.DataAnnotations;

public class ProfileViewModel
{
    [Required(ErrorMessage = "Tên hiển thị không được để trống")]
    public string? UserName { get; set; }

    [Required(ErrorMessage = "Email không được để trống")]
    [EmailAddress(ErrorMessage = "Email không hợp lệ")]
    public string? Email { get; set; }

    [Phone(ErrorMessage = "Số điện thoại không hợp lệ")]
    public string? PhoneNumber { get; set; }
}
