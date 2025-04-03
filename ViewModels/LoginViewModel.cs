using System.ComponentModel.DataAnnotations;

public class LoginViewModel
{
    [Required]
    public string LoginIdentifier { get; set; } = string.Empty; // Dùng thay cho EmailOrPhoneNumber

    [Required]
    [DataType(DataType.Password)]
    public string Password { get; set; } = string.Empty;

    public bool RememberMe { get; set; } = false; // Thêm RememberMe nếu cần
}

