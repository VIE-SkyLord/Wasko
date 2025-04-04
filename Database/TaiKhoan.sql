-- =============================================
-- 1. Bảng TaiKhoan
-- =============================================
CREATE TABLE TaiKhoan
(
    IdTK INT IDENTITY(1,1) PRIMARY KEY,
    HoTen NVARCHAR(100) NOT NULL,
    SDT VARCHAR(20) NULL,
    Email VARCHAR(100) NOT NULL UNIQUE,  -- UNIQUE để tránh trùng lặp
    MatKhau VARCHAR(256) NOT NULL,
	NgayDangKy DATETIME NOT NULL DEFAULT(GETDATE()),
	-- Các cột để quản lý khóa tài khoản
	BiKhoa BIT NOT NULL DEFAULT(0),
	LyDoKhoa NVARCHAR(500) NULL,

	VaiTro NVARCHAR(50) NOT NULL DEFAULT('User')
    -- ví dụ: 'QuanLyCapCao' (super admin), 'KiemDuyetVien', 'User'...
);

-- Tạo chỉ mục để tối ưu tìm kiếm theo Email, SDT
CREATE NONCLUSTERED INDEX IX_TaiKhoan_Email ON TaiKhoan(Email);
CREATE NONCLUSTERED INDEX IX_TaiKhoan_SDT ON TaiKhoan(SDT);

-- =============================================
-- 3. Bảng UserSession
--    Mỗi IdTK chỉ có 1 dòng active tại 1 thời điểm
-- =============================================
CREATE TABLE UserSession
(
    IdTK INT NOT NULL PRIMARY KEY, -- Mỗi tài khoản chỉ có 1 phiên tại 1 thời điểm
    SessionToken VARCHAR(1000) NOT NULL,
    DeviceInfo NVARCHAR(200) NULL,
    LoginTime DATETIME NOT NULL DEFAULT GETDATE(),
    ExpireTime DATETIME NULL,
    IsActive BIT NOT NULL DEFAULT (0),  -- 0: offline, 1: online
    CONSTRAINT FK_UserSession_TaiKhoan
        FOREIGN KEY (IdTK) REFERENCES TaiKhoan(IdTK)
        ON DELETE CASCADE
);

-- =============================================
-- Stored Procedure: sp_TaiKhoan_DangNhap
-- =============================================
CREATE PROCEDURE sp_TaiKhoan_DangNhap
    @EmailHoacSDT VARCHAR(100),
    @MatKhau VARCHAR(256),
    @DeviceInfo NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdTK INT;
    SELECT @IdTK = IdTK
    FROM TaiKhoan
    WHERE (Email = @EmailHoacSDT OR SDT = @EmailHoacSDT)
      AND MatKhau = @MatKhau;

    IF @IdTK IS NULL
    BEGIN
        RAISERROR('Thông tin đăng nhập không hợp lệ!', 16, 1);
        RETURN;
    END

    -- Kiểm tra phiên đăng nhập hiện tại
    DECLARE @IsActive BIT;
    SELECT @IsActive = IsActive
    FROM UserSession
    WHERE IdTK = @IdTK;

    IF (@IsActive = 1)
    BEGIN
        RAISERROR(N'Tài khoản đang đăng nhập trên thiết bị khác!', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @NewToken VARCHAR(1000) = CONVERT(VARCHAR(36), NEWID());

        IF EXISTS (SELECT 1 FROM UserSession WHERE IdTK = @IdTK)
        BEGIN
            UPDATE UserSession
            SET SessionToken = @NewToken,
                DeviceInfo = @DeviceInfo,
                LoginTime = GETDATE(),
                IsActive = 1
            WHERE IdTK = @IdTK;
        END
        ELSE
        BEGIN
            INSERT INTO UserSession(IdTK, SessionToken, DeviceInfo, LoginTime, IsActive)
            VALUES(@IdTK, @NewToken, @DeviceInfo, GETDATE(), 1);
        END

        COMMIT TRANSACTION;
        SELECT 'Đăng nhập thành công!' AS Message, @IdTK AS IdTK, @NewToken AS SessionToken;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        RAISERROR('Lỗi không xác định', 16, 1);
    END CATCH
END
GO

-- =============================================
-- Stored Procedure: sp_TaiKhoan_DangXuat
-- =============================================
CREATE PROCEDURE sp_TaiKhoan_DangXuat
    @IdTK INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE UserSession
        SET IsActive = 0
        WHERE IdTK = @IdTK;

        COMMIT TRANSACTION;
        SELECT 'Đăng xuất thành công!' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        RAISERROR('Lỗi không xác định', 16, 1);
    END CATCH
END
GO

-- =============================================
-- Stored Procedure: sp_TaiKhoan_DoiMatKhauChuaDangNhap
-- =============================================
CREATE PROCEDURE sp_TaiKhoan_DoiMatKhauChuaDangNhap
    @EmailHoacSDT VARCHAR(100),
    @MatKhauMoi VARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE TaiKhoan
    SET MatKhau = @MatKhauMoi
    WHERE Email = @EmailHoacSDT
       OR SDT = @EmailHoacSDT;

    IF (@@ROWCOUNT = 0)
    BEGIN
        RAISERROR('Không tìm thấy tài khoản!', 16, 1);
        RETURN;
    END

    SELECT 'Đổi mật khẩu thành công (chưa đăng nhập)!' AS Message;
END
GO

-- =============================================
-- Stored Procedure: sp_TaiKhoan_DoiMatKhauDaDangNhap
-- =============================================
CREATE PROCEDURE sp_TaiKhoan_DoiMatKhauDaDangNhap
    @IdTK INT,
    @MatKhauCu VARCHAR(256),
    @MatKhauMoi VARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM TaiKhoan 
                   WHERE IdTK = @IdTK 
                     AND MatKhau = @MatKhauCu)
    BEGIN
        RAISERROR('Mật khẩu cũ không đúng!', 16, 1);
        RETURN;
    END

    UPDATE TaiKhoan
    SET MatKhau = @MatKhauMoi
    WHERE IdTK = @IdTK;

    SELECT 'Đổi mật khẩu thành công (đã đăng nhập)!' AS Message;
END
GO
