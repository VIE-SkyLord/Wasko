INSERT INTO TaiKhoan(HoTen, SDT, Email, MatKhau, VaiTro)
VALUES(N'Quản Lý Cấp Cao', '0900000000', 'admin@hethong.com', 'MatKhauSuperAdmin', 'QuanLyCapCao');

CREATE PROCEDURE sp_QLCC_ThemKiemDuyetVien
    @CallerId INT,            -- IdTK của người gọi (phải là Quản lý cấp cao)
    @HoTen NVARCHAR(100),
    @SoCCCD VARCHAR(20),
    @SDT VARCHAR(20),
    @Email VARCHAR(100),
    @BangCap NVARCHAR(100),
    @MatKhau VARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;
    -- Kiểm tra người gọi có phải Quản lý cấp cao?
    IF NOT EXISTS (
        SELECT 1 FROM TaiKhoan 
        WHERE IdTK = @CallerId
          AND VaiTro = 'QuanLyCapCao'
    )
    BEGIN
        RAISERROR(N'Bạn không có quyền thực hiện thao tác này!', 16, 1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM TaiKhoan WHERE Email = @Email)
    BEGIN
        RAISERROR(N'Email kiểm duyệt viên đã tồn tại!', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Thêm tài khoản (VaiTro = 'KiemDuyetVien')
        INSERT INTO TaiKhoan(HoTen, SDT, Email, MatKhau, VaiTro)
        VALUES(@HoTen, @SDT, @Email, @MatKhau, 'KiemDuyetVien');

        DECLARE @NewIdTK INT = SCOPE_IDENTITY();

        -- 2. Thêm thông tin riêng trong KiemDuyetVien
        INSERT INTO KiemDuyetVien(IdTK, SoCCCD, BangCap)
        VALUES(@NewIdTK, @SoCCCD, @BangCap);

        COMMIT TRANSACTION;
        SELECT N'Thêm kiểm duyệt viên thành công!', @NewIdTK AS IdTK;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        RAISERROR('Lỗi không xác định', 16, 1);
    END CATCH
END
GO

CREATE PROCEDURE sp_QLCC_SuaKiemDuyetVien
    @CallerId INT,
    @IdTK INT,            -- Id của kiểm duyệt viên
    @HoTen NVARCHAR(100),
    @SoCCCD VARCHAR(20),
    @SDT VARCHAR(20),
    @Email VARCHAR(100),
    @BangCap NVARCHAR(100),
    @MatKhau VARCHAR(256) = NULL,       -- có thể đổi mật khẩu
    @MatKhauNhapLai VARCHAR(256) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra quyền
    IF NOT EXISTS (
        SELECT 1 FROM TaiKhoan
        WHERE IdTK = @CallerId
          AND VaiTro = 'QuanLyCapCao'
    )
    BEGIN
        RAISERROR(N'Bạn không có quyền thực hiện thao tác này!', 16, 1);
        RETURN;
    END

    -- Kiểm tra tồn tại
    IF NOT EXISTS (
        SELECT 1 FROM TaiKhoan
        WHERE IdTK = @IdTK
          AND VaiTro = 'KiemDuyetVien'
    )
    BEGIN
        RAISERROR(N'Không tìm thấy kiểm duyệt viên!', 16, 1);
        RETURN;
    END

    -- Kiểm tra mật khẩu
    IF @MatKhau IS NOT NULL AND @MatKhau <> @MatKhauNhapLai
    BEGIN
        RAISERROR(N'Mật khẩu nhập lại không khớp!', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @MatKhau IS NOT NULL
        BEGIN
            UPDATE TaiKhoan
            SET HoTen = @HoTen,
                SDT = @SDT,
                Email = @Email,
                MatKhau = @MatKhau
            WHERE IdTK = @IdTK;
        END
        ELSE
        BEGIN
            UPDATE TaiKhoan
            SET HoTen = @HoTen,
                SDT = @SDT,
                Email = @Email
            WHERE IdTK = @IdTK;
        END

        UPDATE KiemDuyetVien
        SET SoCCCD = @SoCCCD,
            BangCap = @BangCap
        WHERE IdTK = @IdTK;

        COMMIT TRANSACTION;
        SELECT N'Sửa kiểm duyệt viên thành công!' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
RAISERROR('Lỗi không xác định', 16, 1);
    END CATCH
END
GO

CREATE PROCEDURE sp_QLCC_XoaKiemDuyetVien
    @CallerId INT,
    @IdTK INT  -- kiểm duyệt viên cần xoá
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1 FROM TaiKhoan
        WHERE IdTK = @CallerId
          AND VaiTro = 'QuanLyCapCao'
    )
    BEGIN
        RAISERROR(N'Bạn không có quyền thực hiện thao tác này!', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (
        SELECT 1 FROM TaiKhoan
        WHERE IdTK = @IdTK
          AND VaiTro = 'KiemDuyetVien'
    )
    BEGIN
        RAISERROR(N'Không tìm thấy kiểm duyệt viên!', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM TaiKhoan
        WHERE IdTK = @IdTK;  -- ON DELETE CASCADE sẽ xoá luôn KiemDuyetVien

        COMMIT TRANSACTION;
        SELECT N'Xoá kiểm duyệt viên thành công!' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
RAISERROR('Lỗi không xác định', 16, 1);
    END CATCH
END
GO
