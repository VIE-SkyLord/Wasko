using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Wasko.Models
{
    public class KhoaHoc
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int IdKhoaHoc { get; set; }
        
        public int? IdBanGoc { get; set; }
        
        [Required]
        public string IdGiangVien { get; set; }
        
        [Required]
        [StringLength(255)]
        public string TenKhoaHoc { get; set; }
        
        [Required]
        [StringLength(50)]
        public string TrangThai { get; set; }
        
        public string MoTa { get; set; }
        
        [Required]
        [Column(TypeName = "Date")]
        public DateTime NgayTao { get; set; } = DateTime.Now;
        
        [Column(TypeName = "Date")]
        public DateTime? NgayXuatBan { get; set; }
        
        public string? IdNguoiDuyet { get; set; }
        
        [Column(TypeName = "Date")]
        public DateTime? NgayDuyet { get; set; }
        
        public int? IdChuDe { get; set; }
        
        [Required]
        [StringLength(50)]
        public string CapDo { get; set; }
        
        public int SoLuongVideo { get; set; } = 0;
        
        [Range(0, int.MaxValue)]
        public int GiaKhoaHoc { get; set; }
        
        public float SoSaoTrungBinh { get; set; } = 0;
        
        // Navigation properties
        [ForeignKey("IdGiangVien")]
        public virtual ApplicationUser GiangVien { get; set; }
        
        [ForeignKey("IdNguoiDuyet")]
        public virtual ApplicationUser NguoiDuyet { get; set; }
        
        [ForeignKey("IdChuDe")]
        public virtual ChuDe ChuDe { get; set; }
        
        // Relationship with BaiHoc
        public virtual ICollection<BaiHoc> DanhSachBaiHoc { get; set; }
    }
    
    public class BaiHoc
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int IdBaiHoc { get; set; }
        
        [Required]
        public int IdKhoaHoc { get; set; }
        
        [Required]
        [StringLength(255)]
        public string TenBaiHoc { get; set; }
        
        [StringLength(1000)]
        public string MoTa { get; set; }
        
        // Navigation property
        [ForeignKey("IdKhoaHoc")]
        public virtual KhoaHoc KhoaHoc { get; set; }
        
        // Relationships
        public virtual ICollection<TaiLieuHocTap> DanhSachTaiLieu { get; set; }
        public virtual BaiKiemTra BaiKiemTra { get; set; }
    }
    
    public class TaiLieuHocTap
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int IdTaiLieu { get; set; }
        
        [Required]
        public int IdBaiHoc { get; set; }
        
        [Required]
        [StringLength(50)]
        public string LoaiTaiLieu { get; set; }
        
        [Required]
        [StringLength(255)]
        public string URL { get; set; }
        
        // Navigation property
        [ForeignKey("IdBaiHoc")]
        public virtual BaiHoc BaiHoc { get; set; }
    }
    
    public class BaiKiemTra
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int IdBaiKiemTra { get; set; }
        
        [Required]
        public int IdBaiHoc { get; set; }
        
        [Range(0, 100)]
        public int PhanTramDat { get; set; } = 0;
        
        // Navigation property
        [ForeignKey("IdBaiHoc")]
        public virtual BaiHoc BaiHoc { get; set; }
        
        // Relationship
        public virtual ICollection<CauHoiTracNghiem> DanhSachCauHoi { get; set; }
    }
    
    public class CauHoiTracNghiem
    {
        [Key]
        public int IdCauHoi { get; set; }
        
        [Required]
        public int IdBaiKiemTra { get; set; }
        
        [StringLength(255)]
        public string NoiDungCauHoi { get; set; }
        
        [Required]
        public int IdDapAn { get; set; }
        
        public int DiemCauHoi { get; set; } = 10;
        
        // Navigation property
        [ForeignKey("IdBaiKiemTra")]
        public virtual BaiKiemTra BaiKiemTra { get; set; }
        
        // Relationship
        public virtual ICollection<PhuongAn> DanhSachPhuongAn { get; set; }
    }
    
    public class PhuongAn
    {
        [Key]
        public int IdPhuongAn { get; set; }
        
        [Required]
        public int IdCauHoi { get; set; }
        
        [StringLength(255)]
        public string NoiDungPhuongAn { get; set; }
        
        // Navigation property
        [ForeignKey("IdCauHoi")]
        public virtual CauHoiTracNghiem CauHoi { get; set; }
    }
}
