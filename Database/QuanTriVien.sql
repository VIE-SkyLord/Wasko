-- =============================================
-- Bảng QuanTriVien (1-1 với TaiKhoan)
-- =============================================
CREATE TABLE KiemDuyetVien
(
    IdTK INT NOT NULL PRIMARY KEY,
    SoCCCD VARCHAR(20) NOT NULL,
    BangCap NVARCHAR(100) NULL,

    CONSTRAINT FK_KiemDuyetVien_TaiKhoan
        FOREIGN KEY (IdTK) REFERENCES TaiKhoan(IdTK)
        ON DELETE CASCADE
);
CREATE PROCEDURE sp_KiemDuyetVien_SuaThongTin
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
        RAISERROR(N'Tài khoản không tồn tại!', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Cập nhật thông tin tài khoản
        UPDATE TaiKhoan
        SET HoTen = @HoTen,
            SDT = @SDT,
            Email = @Email
        WHERE IdTK = @IdTK;

        -- Cập nhật bảng QuanTriVien
        UPDATE QuanTriVien
        SET BangCap = @BangCap
        WHERE IdTK = @IdTK;

        COMMIT TRANSACTION;
        SELECT 'Cập nhật thông tin quản trị viên thành công!' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        RAISERROR('Lỗi không xác định', 16, 1);
    END CATCH
END
GO

CREATE PROCEDURE sp_KhoaTaiKhoan
    @EmailHoacSDT VARCHAR(100),
    @LyDoKhoa NVARCHAR(500) = NULL,
    @Khoa BIT = 1  -- 1: khoá, 0: mở
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @Khoa = 1
        BEGIN
            -- Khoá tài khoản
            UPDATE TaiKhoan
            SET BiKhoa = 1,
                LyDoKhoa = @LyDoKhoa
            WHERE Email = @EmailHoacSDT
               OR SDT = @EmailHoacSDT;

            IF @@ROWCOUNT = 0
            BEGIN
                RAISERROR(N'Không tìm thấy tài khoản để khoá!', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END

            -- Đồng thời đánh dấu session offline (nếu đang online)
            UPDATE UserSession
            SET IsActive = 0
            WHERE IdTK IN (
                SELECT IdTK FROM TaiKhoan 
                WHERE Email = @EmailHoacSDT 
                   OR SDT = @EmailHoacSDT
            );

            COMMIT TRANSACTION;
            SELECT N'Đã khoá tài khoản. Lý do: ' + ISNULL(@LyDoKhoa, '') AS Message;
        END
        ELSE
        BEGIN
            -- Mở tài khoản (bỏ khoá)
            UPDATE TaiKhoan
            SET BiKhoa = 0,
                LyDoKhoa = NULL
            WHERE Email = @EmailHoacSDT
               OR SDT = @EmailHoacSDT;

            IF @@ROWCOUNT = 0
            BEGIN
                RAISERROR(N'Không tìm thấy tài khoản để mở!', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END

            COMMIT TRANSACTION;
            SELECT N'Tài khoản đã được mở khoá!' AS Message;
        END
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        RAISERROR('Lỗi không xác định', 16, 1);
    END CATCH
END
GO

