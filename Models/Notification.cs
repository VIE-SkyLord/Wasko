using System;
using System.ComponentModel.DataAnnotations;

namespace Wasko.Models
{
    public class ThongBao
    {
        public int Id { get; set; }
        
        [Required]
        [StringLength(500)]
        [Display(Name = "Nội dung")]
        public string NoiDung { get; set; }
        
        [Display(Name = "Thời gian")]
        public DateTime ThoiGian { get; set; } = DateTime.Now;
        
        [Required]
        [StringLength(50)]
        [Display(Name = "Vai trò người nhận")]
        public string NguoiNhanRole { get; set; } = "GiangVien";
        
        [Display(Name = "Đã đọc")]
        public bool DaDoc { get; set; } = false;
    }
}