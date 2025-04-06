using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using Wasko.Models;

namespace Wasko.Data
{
    public class ApplicationDbContext : IdentityDbContext<ApplicationUser>
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options)
        {
        }

        public DbSet<KhoaHoc> KhoaHoc { get; set; }
        public DbSet<BaiHoc> BaiHoc { get; set; }
        public DbSet<TaiLieuHocTap> TaiLieuHocTap { get; set; }
        public DbSet<BaiKiemTra> BaiKiemTra { get; set; }
        public DbSet<CauHoiTracNghiem> CauHoiTracNghiem { get; set; }
        public DbSet<PhuongAn> PhuongAn { get; set; }
        public DbSet<ChuDe> ChuDe { get; set; }
        public DbSet<ThongBao> ThongBao { get; set; }

        protected override void OnModelCreating(ModelBuilder builder)
        {
            base.OnModelCreating(builder);

            // Configure relationships
            builder.Entity<KhoaHoc>()
                .HasOne(k => k.GiangVien)
                .WithMany()
                .HasForeignKey(k => k.IdGiangVien)
                .OnDelete(DeleteBehavior.Restrict);

            builder.Entity<KhoaHoc>()
                .HasOne(k => k.NguoiDuyet)
                .WithMany()
                .HasForeignKey(k => k.IdNguoiDuyet)
                .OnDelete(DeleteBehavior.Restrict)
                .IsRequired(false);

            builder.Entity<KhoaHoc>()
                .HasOne(k => k.ChuDe)
                .WithMany()
                .HasForeignKey(k => k.IdChuDe)
                .OnDelete(DeleteBehavior.SetNull)
                .IsRequired(false);

            builder.Entity<BaiHoc>()
                .HasOne(b => b.KhoaHoc)
                .WithMany(k => k.DanhSachBaiHoc)
                .HasForeignKey(b => b.IdKhoaHoc)
                .OnDelete(DeleteBehavior.Cascade);

            builder.Entity<TaiLieuHocTap>()
                .HasOne(t => t.BaiHoc)
                .WithMany(b => b.DanhSachTaiLieu)
                .HasForeignKey(t => t.IdBaiHoc)
                .OnDelete(DeleteBehavior.Cascade);

            builder.Entity<BaiKiemTra>()
                .HasOne(kt => kt.BaiHoc)
                .WithOne(b => b.BaiKiemTra)
                .HasForeignKey<BaiKiemTra>(kt => kt.IdBaiHoc)
                .OnDelete(DeleteBehavior.Cascade);

            builder.Entity<CauHoiTracNghiem>()
                .HasOne(ch => ch.BaiKiemTra)
                .WithMany(kt => kt.DanhSachCauHoi)
                .HasForeignKey(ch => ch.IdBaiKiemTra)
                .OnDelete(DeleteBehavior.Cascade);

            builder.Entity<PhuongAn>()
                .HasOne(pa => pa.CauHoi)
                .WithMany(ch => ch.DanhSachPhuongAn)
                .HasForeignKey(pa => pa.IdCauHoi)
                .OnDelete(DeleteBehavior.Cascade);
            // Cấu hình cho model ChuDe
            builder.Entity<ChuDe>()
                .Property(p => p.TenChuDe)
                .IsRequired()
                .HasMaxLength(200);
                
            // Cấu hình cho model ThongBao
            builder.Entity<ThongBao>()
                .Property(p => p.NoiDung)
                .IsRequired()
                .HasMaxLength(500);
                
            builder.Entity<ThongBao>()
                .Property(p => p.NguoiNhanRole)
                .IsRequired()
                .HasMaxLength(50);
        }
    }
}