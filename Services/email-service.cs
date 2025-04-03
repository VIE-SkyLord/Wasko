using Microsoft.Extensions.Configuration;
using System;
using System.Net;
using System.Net.Mail;
using System.Threading.Tasks;

public class EmailService
{
    private readonly IConfiguration _configuration;
    private readonly string _senderEmail;
    private readonly string _senderPassword;
    private readonly string _smtpHost;
    private readonly int _smtpPort;
    private readonly string _baseUrl;

    public EmailService(IConfiguration configuration)
    {
        _configuration = configuration;
        
        // Lấy thông tin cấu hình từ appsettings.json
        _senderEmail = _configuration["EmailSettings:SenderEmail"];
        _senderPassword = _configuration["EmailSettings:SenderPassword"];
        _smtpHost = _configuration["EmailSettings:SmtpHost"];
        _smtpPort = int.Parse(_configuration["EmailSettings:SmtpPort"]);
        _baseUrl = _configuration["AppSettings:BaseUrl"];
    }

    public async Task SendVerificationEmailAsync(string receiverEmail, string token, string userId)
    {
        try
        {
            // Tạo đường dẫn xác minh email
            string verificationLink = $"{_baseUrl}/Account/VerifyEmail?userId={userId}&token={WebUtility.UrlEncode(token)}";
            
            // Nội dung email
            string subject = "Xác minh email tài khoản Wasko";
            string body = $@"
                <html>
                <head>
                    <style>
                        body {{ font-family: Arial, sans-serif; line-height: 1.6; }}
                        .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                        .header {{ background-color: #4a86e8; color: white; padding: 10px; text-align: center; }}
                        .content {{ padding: 20px; }}
                        .button {{ background-color: #4a86e8; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; }}
                    </style>
                </head>
                <body>
                    <div class='container'>
                        <div class='header'>
                            <h2>Xác minh tài khoản Wasko</h2>
                        </div>
                        <div class='content'>
                            <p>Chào bạn,</p>
                            <p>Cảm ơn bạn đã đăng ký tài khoản Wasko. Để hoàn tất quá trình đăng ký, vui lòng xác minh địa chỉ email của bạn bằng cách nhấp vào nút bên dưới:</p>
                            <p style='text-align: center;'>
                                <a href='{verificationLink}' class='button'>Xác minh email</a>
                            </p>
                            <p>Hoặc bạn có thể sao chép và dán đường dẫn sau vào trình duyệt:</p>
                            <p>{verificationLink}</p>
                            <p>Đường dẫn này sẽ hết hạn sau 24 giờ.</p>
                            <p>Nếu bạn không thực hiện yêu cầu này, vui lòng bỏ qua email này.</p>
                            <p>Trân trọng,<br/>Đội ngũ Wasko</p>
                        </div>
                    </div>
                </body>
                </html>";

            // Gửi email
            using (var client = new SmtpClient(_smtpHost, _smtpPort))
            {
                client.EnableSsl = true;
                client.Credentials = new NetworkCredential(_senderEmail, _senderPassword);

                var mailMessage = new MailMessage(_senderEmail, receiverEmail, subject, body)
                {
                    IsBodyHtml = true
                };

                await client.SendMailAsync(mailMessage);
            }
        }
        catch (Exception ex)
        {
            // Ghi log lỗi
            System.Diagnostics.Debug.WriteLine($"Error sending verification email: {ex.Message}");
            throw;
        }
    }

    public async Task SendPasswordResetEmailAsync(string receiverEmail, string token, string userId)
    {
        try
        {
            // Tạo đường dẫn đặt lại mật khẩu
            string resetLink = $"{_baseUrl}/Account/ResetPassword?userId={userId}&token={WebUtility.UrlEncode(token)}";
            
            // Nội dung email
            string subject = "Đặt lại mật khẩu tài khoản Wasko";
            string body = $@"
                <html>
                <head>
                    <style>
                        body {{ font-family: Arial, sans-serif; line-height: 1.6; }}
                        .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                        .header {{ background-color: #4a86e8; color: white; padding: 10px; text-align: center; }}
                        .content {{ padding: 20px; }}
                        .button {{ background-color: #4a86e8; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; }}
                    </style>
                </head>
                <body>
                    <div class='container'>
                        <div class='header'>
                            <h2>Đặt lại mật khẩu Wasko</h2>
                        </div>
                        <div class='content'>
                            <p>Chào bạn,</p>
                            <p>Chúng tôi nhận được yêu cầu đặt lại mật khẩu cho tài khoản Wasko của bạn. Vui lòng nhấp vào nút bên dưới để đặt lại mật khẩu:</p>
                            <p style='text-align: center;'>
                                <a href='{resetLink}' class='button'>Đặt lại mật khẩu</a>
                            </p>
                            <p>Hoặc bạn có thể sao chép và dán đường dẫn sau vào trình duyệt:</p>
                            <p>{resetLink}</p>
                            <p>Đường dẫn này sẽ hết hạn sau 24 giờ.</p>
                            <p>Nếu bạn không thực hiện yêu cầu này, vui lòng bỏ qua email này và bảo vệ tài khoản của bạn.</p>
                            <p>Trân trọng,<br/>Đội ngũ Wasko</p>
                        </div>
                    </div>
                </body>
                </html>";

            // Gửi email
            using (var client = new SmtpClient(_smtpHost, _smtpPort))
            {
                client.EnableSsl = true;
                client.Credentials = new NetworkCredential(_senderEmail, _senderPassword);

                var mailMessage = new MailMessage(_senderEmail, receiverEmail, subject, body)
                {
                    IsBodyHtml = true
                };

                await client.SendMailAsync(mailMessage);
            }
        }
        catch (Exception ex)
        {
            // Ghi log lỗi
            System.Diagnostics.Debug.WriteLine($"Error sending password reset email: {ex.Message}");
            throw;
        }
    }
}
