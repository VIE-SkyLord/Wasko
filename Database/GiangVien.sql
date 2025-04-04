-- =============================================
-- 2. Bảng GiangVien (Kế thừa 1-1 với TaiKhoan)
-- =============================================
CREATE TABLE GiangVien
(
    IdTK INT NOT NULL PRIMARY KEY,
    SoCCCD VARCHAR(20) NOT NULL,
    BangCap NVARCHAR(100) NULL,
    MucPhat DATE NULL,
    CONSTRAINT FK_GiangVien_TaiKhoan
        FOREIGN KEY (IdTK) REFERENCES TaiKhoan(IdTK)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
CREATE PROCEDURE sp_GiangVien_DangKy
    @HoTen NVARCHAR(100),
    @SoCCCD VARCHAR(20),
    @SDT VARCHAR(20),
    @Email VARCHAR(100),
    @MatKhau VARCHAR(256),
    @MatKhauNhapLai VARCHAR(256),
    @BangCap NVARCHAR(100) = NULL,
    @MucPhat DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF (@MatKhau <> @MatKhauNhapLai)
    BEGIN
        RAISERROR('Mật khẩu nhập lại không khớp!', 16, 1);
        RETURN;
    END

    -- Kiểm tra email đã tồn tại chưa
    IF EXISTS (SELECT 1 FROM TaiKhoan WHERE Email = @Email)
    BEGIN
        RAISERROR('Email đã tồn tại!', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO TaiKhoan(HoTen, SDT, Email, MatKhau)
        VALUES(@HoTen, @SDT, @Email, @MatKhau);

        DECLARE @NewIdTK INT = SCOPE_IDENTITY();

        INSERT INTO GiangVien(IdTK, SoCCCD, BangCap, MucPhat)
        VALUES(@NewIdTK, @SoCCCD, @BangCap, @MucPhat);

        COMMIT TRANSACTION;
        SELECT 'Đăng ký giảng viên thành công!' AS Message, @NewIdTK AS IdTK;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        RAISERROR('Lỗi không xác định', 16, 1);
    END CATCH
END
GO

CREATE PROCEDURE sp_GiangVien_SuaThongTin
    @IdTK INT,
    @HoTen NVARCHAR(100),
    @SDT VARCHAR(20),
    @Email VARCHAR(100),
    @BangCap NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM TaiKhoan WHERE IdTK = @IdTK)
    BEGIN
        RAISERROR('Tài khoản không tồn tại!', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE TaiKhoan
        SET HoTen = @HoTen,
            SDT = @SDT,
            Email = @Email
        WHERE IdTK = @IdTK;

        UPDATE GiangVien
        SET BangCap = @BangCap
        WHERE IdTK = @IdTK;

        COMMIT TRANSACTION;
        SELECT 'Cập nhật thông tin giảng viên thành công!' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        RAISERROR('Lỗi không xác định', 16, 1);
    END CATCH
END
GO
