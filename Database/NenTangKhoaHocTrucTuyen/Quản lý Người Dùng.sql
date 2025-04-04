USE NenTangKhoaHocTrucTuyen
GO

-- Procedure đăng ký tài khoản
CREATE PROCEDURE sp_DangKyTaiKhoan
    @TenNguoiDung NVARCHAR(100),
    @MatKhau NVARCHAR(255),
    @Email NVARCHAR(100),
    @SoDienThoai NVARCHAR(20) = NULL,
    @MaVaiTro INT = 1 -- Mặc định là học viên
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Kiểm tra email đã tồn tại chưa
    IF EXISTS (SELECT 1 FROM NguoiDung WHERE Email = @Email)
    BEGIN
        SELECT 0 AS KetQua, N'Email đã được sử dụng' AS ThongBao
        RETURN
    END
    
    BEGIN TRY
        INSERT INTO NguoiDung (TenNguoiDung, MatKhau, Email, SoDienThoai, MaVaiTro, SoDu)
        VALUES (@TenNguoiDung, @MatKhau, @Email, @SoDienThoai, @MaVaiTro, 0)
        
        -- Nếu là giảng viên, thêm vào bảng GiangVien
        IF @MaVaiTro = 2
        BEGIN
            DECLARE @MaNguoiDung INT = SCOPE_IDENTITY()
            INSERT INTO GiangVien (MaGiangVien, TyLeLoiNhuan)
            VALUES (@MaNguoiDung, 70.00)
        END
        
        SELECT 1 AS KetQua, N'Đăng ký tài khoản thành công' AS ThongBao, SCOPE_IDENTITY() AS MaNguoiDung
    END TRY
    BEGIN CATCH
        SELECT 0 AS KetQua, ERROR_MESSAGE() AS ThongBao
    END CATCH
END
GO

-- Procedure đăng nhập
CREATE PROCEDURE sp_DangNhap
    @TaiKhoan NVARCHAR(100), -- Email hoặc số điện thoại
    @MatKhau NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @MaNguoiDung INT
    DECLARE @TenNguoiDung NVARCHAR(100)
    DECLARE @MaVaiTro INT
    
    -- Kiểm tra đăng nhập bằng email
    IF EXISTS (SELECT 1 FROM NguoiDung WHERE Email = @TaiKhoan AND MatKhau = @MatKhau)
    BEGIN
        SELECT @MaNguoiDung = MaNguoiDung, @TenNguoiDung = TenNguoiDung, @MaVaiTro = MaVaiTro
        FROM NguoiDung WHERE Email = @TaiKhoan AND MatKhau = @MatKhau
        
        SELECT 1 AS KetQua, N'Đăng nhập thành công' AS ThongBao, 
               @MaNguoiDung AS MaNguoiDung, @TenNguoiDung AS TenNguoiDung, @MaVaiTro AS MaVaiTro
        RETURN
    END
    
    -- Kiểm tra đăng nhập bằng số điện thoại
    