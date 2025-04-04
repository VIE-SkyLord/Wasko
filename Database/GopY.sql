IF OBJECT_ID('dbo.GopY', 'U') IS NOT NULL
    DROP TABLE dbo.GopY;
GO

CREATE TABLE dbo.GopY
(
    IdGopY INT IDENTITY(1,1) PRIMARY KEY,
    IdNguoiGopY INT NOT NULL,           -- Tham chiếu TaiKhoan(IdTK)
    NoiDungGopY NVARCHAR(MAX) NOT NULL, -- Nội dung góp ý
    NgayGopY DATETIME NOT NULL 
        CONSTRAINT DF_GopY_NgayGopY DEFAULT(GETDATE()),
    TrangThai NVARCHAR(50) NOT NULL 
        CONSTRAINT DF_GopY_TrangThai DEFAULT(N'moi'),

    CONSTRAINT FK_GopY_TaiKhoan
        FOREIGN KEY (IdNguoiGopY)
        REFERENCES dbo.TaiKhoan(IdTK)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
GO

-- Tạo Index cho IdNguoiGopY (nếu cần)
CREATE NONCLUSTERED INDEX IX_GopY_IdNguoiGopY
    ON dbo.GopY(IdNguoiGopY);
GO

IF OBJECT_ID('dbo.spGopY_Them', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spGopY_Them;
GO

IF OBJECT_ID('dbo.spGopY_Them', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spGopY_Them;
GO

CREATE PROCEDURE dbo.spGopY_Them
    @IdNguoiGopY INT,
    @NoiDungGopY NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1) Kiểm tra tài khoản tồn tại không
    IF NOT EXISTS (SELECT 1 FROM dbo.TaiKhoan WHERE IdTK = @IdNguoiGopY)
    BEGIN
        RAISERROR(N'Tài khoản không tồn tại!', 16, 1);
        RETURN;
    END

    -- 2) Lấy vai trò của tài khoản
    DECLARE @VaiTro NVARCHAR(50);
    SELECT @VaiTro = VaiTro
    FROM dbo.TaiKhoan
    WHERE IdTK = @IdNguoiGopY;

    -- 3) Nếu vai trò là KiemDuyetVien hoặc QuanLyCapCao => Không cho phép góp ý
    IF @VaiTro IN (N'KiemDuyetVien', N'QuanLyCapCao')
    BEGIN
        RAISERROR(N'Bạn không có quyền gửi góp ý!', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO dbo.GopY (IdNguoiGopY, NoiDungGopY)
        VALUES (@IdNguoiGopY, @NoiDungGopY);

        COMMIT TRANSACTION;
        SELECT N'Thêm góp ý thành công!' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        RAISERROR(N'Lỗi khi thêm góp ý!', 16, 1);
    END CATCH
END;
GO

IF OBJECT_ID('dbo.spGopY_Xoa', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spGopY_Xoa;
GO

CREATE PROCEDURE dbo.spGopY_Xoa
    @IdGopY INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra góp ý có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM dbo.GopY WHERE IdGopY = @IdGopY)
    BEGIN
        RAISERROR(N'Góp ý không tồn tại!', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM dbo.GopY
        WHERE IdGopY = @IdGopY;

        COMMIT TRANSACTION;
        SELECT N'Xóa góp ý thành công!' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        RAISERROR(N'Lỗi khi xóa góp ý!', 16, 1);
    END CATCH
END;
GO
