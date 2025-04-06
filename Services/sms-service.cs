using Microsoft.Extensions.Configuration;
using System;
using System.Threading.Tasks;
using System.Net.Http;
using System.Collections.Generic;

public class SmsService
{
    private readonly IConfiguration _configuration;
    private readonly string _apiKey;
    private readonly string _apiSecret;
    private readonly string _fromNumber;
    private readonly HttpClient _httpClient;

    public SmsService(IConfiguration configuration, HttpClient httpClient)
    {
        _configuration = configuration;
        _httpClient = httpClient;
        
        // Lấy thông tin cấu hình từ appsettings.json
        _apiKey = _configuration["SmsSettings:ApiKey"];
        _apiSecret = _configuration["SmsSettings:ApiSecret"];
        _fromNumber = _configuration["SmsSettings:FromNumber"];
    }

    public async Task SendVerificationSmsAsync(string phoneNumber, string token)
    {
        try
        {
            // Định dạng lại số điện thoại để đảm bảo có mã quốc gia
            phoneNumber = FormatPhoneNumber(phoneNumber);
            
            // Nội dung tin nhắn
            string message = $"Mã xác minh tài khoản Wasko của bạn là: {token}. Mã này có hiệu lực trong 10 phút.";
            
            // Gửi SMS sử dụng API của nhà cung cấp dịch vụ
            await SendSmsViaProviderAsync(phoneNumber, message);
        }
        catch (Exception ex)
        {
            // Ghi log lỗi
            System.Diagnostics.Debug.WriteLine($"Error sending verification SMS: {ex.Message}");
            throw;
        }
    }

    public async Task SendPasswordResetSmsAsync(string phoneNumber, string token)
    {
        try
        {
            // Định dạng lại số điện thoại
            phoneNumber = FormatPhoneNumber(phoneNumber);
            
            // Nội dung tin nhắn
            string message = $"Mã đặt lại mật khẩu Wasko của bạn là: {token}. Mã này có hiệu lực trong 10 phút.";
            
            // Gửi SMS
            await SendSmsViaProviderAsync(phoneNumber, message);
        }
        catch (Exception ex)
        {
            // Ghi log lỗi
            System.Diagnostics.Debug.WriteLine($"Error sending password reset SMS: {ex.Message}");
            throw;
        }
    }

    // Phương thức này sẽ gửi SMS thông qua API của nhà cung cấp dịch vụ
    private async Task SendSmsViaProviderAsync(string phoneNumber, string message)
    {
        try
        {
            // Đây là ví dụ giao tiếp với API của nhà cung cấp SMS
            // Trong thực tế, bạn cần thay thế bằng nhà cung cấp thực của mình (như Twilio, Nexmo, ...)
            
            var content = new FormUrlEncodedContent(new Dictionary<string, string>
            {
                { "api_key", _apiKey },
                { "api_secret", _apiSecret },
                { "from", _fromNumber },
                { "to", phoneNumber },
                { "text", message }
            });

            // Thay url api dưới đây bằng API thực của nhà cung cấp
            var response = await _httpClient.PostAsync("https://api.yoursmsservice.com/send-sms", content);
            
            // Kiểm tra phản hồi
            if (!response.IsSuccessStatusCode)
            {
                throw new Exception($"SMS service API returned status code: {response.StatusCode}");
            }
            
            var responseContent = await response.Content.ReadAsStringAsync();
            // Xử lý phản hồi nếu cần
        }
        catch (Exception ex)
        {
            // Ghi log lỗi
            System.Diagnostics.Debug.WriteLine($"Error in SendSmsViaProviderAsync: {ex.Message}");
            throw;
        }
    }

    // Định dạng lại số điện thoại để đảm bảo có mã quốc gia
    private string FormatPhoneNumber(string phoneNumber)
    {
        // Loại bỏ các ký tự không phải số
        phoneNumber = System.Text.RegularExpressions.Regex.Replace(phoneNumber, @"[^\d]", "");
        
        // Đảm bảo số điện thoại Việt Nam bắt đầu bằng +84
        if (phoneNumber.StartsWith("0"))
        {
            phoneNumber = "+84" + phoneNumber.Substring(1);
        }
        else if (!phoneNumber.StartsWith("+"))
        {
            // Nếu không bắt đầu bằng + hoặc 0, thêm mã quốc gia +84 (Việt Nam)
            phoneNumber = "+84" + phoneNumber;
        }
        
        return phoneNumber;
    }
}
