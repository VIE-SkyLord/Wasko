-- =============================================
-- Bảng HOCVIEN (1-1 với TAIKHOAN)
-- =============================================
CREATE TABLE HocVien
(
    IdTK INT NOT NULL PRIMARY KEY,
    ThoiGianDoiTenLanCuoi DATETIME NULL,
    SoLuongKhoaHoc INT NOT NULL DEFAULT(0),
    CONSTRAINT FK_HocVien_TaiKhoan
        FOREIGN KEY (IdTK) REFERENCES TaiKhoan(IdTK)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
CREATE PROCEDURE sp_HocVien_DangKy
    @HoTen NVARCHAR(100),
    @SDT VARCHAR(20),
    @Email VARCHAR(100),
    @MatKhau VARCHAR(256),
    @MatKhauNhapLai VARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Kiểm tra mật khẩu nhập lại
    IF (@MatKhau <> @MatKhauNhapLai)
    BEGIN
        RAISERROR('Mật khẩu nhập lại không khớp!', 16, 1);
        RETURN;
    END

    -- 2. Kiểm tra email đã tồn tại chưa
    IF EXISTS (SELECT 1 FROM TaiKhoan WHERE Email = @Email)
    BEGIN
        RAISERROR('Email đã tồn tại!', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 3. Tạo tài khoản trong TaiKhoan
        INSERT INTO TaiKhoan(HoTen, SDT, Email, MatKhau)
        VALUES(@HoTen, @SDT, @Email, @MatKhau);

        DECLARE @NewIdTK INT = SCOPE_IDENTITY();

        -- 4. Tạo thông tin HocVien
        INSERT INTO HocVien(IdTK, ThoiGianDoiTenLanCuoi, SoLuongKhoaHoc)
        VALUES(@NewIdTK, NULL, 0);

        COMMIT TRANSACTION;
        SELECT 'Đăng ký học viên thành công!' AS Message, @NewIdTK AS IdTK;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        RAISERROR('Lỗi không xác định', 16, 1);
    END CATCH
END
GO
CREATE PROCEDURE sp_HocVien_Xoa_XacNhanMatKhau_ById
    @IdTK INT,
    @MatKhau VARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Kiểm tra xem tài khoản có tồn tại và mật khẩu nhập vào có khớp không
        IF NOT EXISTS (
            SELECT 1 
            FROM TaiKhoan 
            WHERE IdTK = @IdTK 
              AND MatKhau = @MatKhau
        )
        BEGIN
            RAISERROR(N'Mật khẩu không đúng hoặc tài khoản không tồn tại!', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Xóa tài khoản, từ đó học viên sẽ bị xóa tự động nếu đã thiết lập ON DELETE CASCADE ở bảng HocVien
        DELETE FROM TaiKhoan
        WHERE IdTK = @IdTK;

        COMMIT TRANSACTION;
        SELECT N'Xóa học viên thành công!' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        RAISERROR('Lỗi không xác định', 16, 1);
    END CATCH
END
GO

CREATE PROCEDURE sp_HocVien_SuaThongTin
    @IdTK INT,
    @HoTen NVARCHAR(100),
    @SDT VARCHAR(20),
    @Email VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Kiểm tra tài khoản có tồn tại không
        IF NOT EXISTS (SELECT 1 FROM TaiKhoan WHERE IdTK = @IdTK)
        BEGIN
            RAISERROR('Tài khoản không tồn tại!', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Cập nhật thông tin trong bảng TaiKhoan
        UPDATE TaiKhoan
        SET HoTen = @HoTen,
            SDT = @SDT,
            Email = @Email
        WHERE IdTK = @IdTK;

        COMMIT TRANSACTION;
        SELECT 'Cập nhật thông tin học viên thành công!' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        RAISERROR('Lỗi không xác định', 16, 1);
    END CATCH
END
GO
