IF OBJECT_ID('dbo.TaiLieu', 'U') IS NOT NULL
    DROP TABLE dbo.TaiLieu;
GO

CREATE TABLE dbo.TaiLieu
(
    IdTaiLieu INT IDENTITY(1,1) PRIMARY KEY,
    IdBaiHoc INT NOT NULL,           -- Khóa ngoại trỏ sang BaiHoc
    URL NVARCHAR(500) NOT NULL,      -- đường dẫn tài liệu

    CONSTRAINT FK_TaiLieu_BaiHoc
        FOREIGN KEY (IdBaiHoc)
        REFERENCES dbo.BaiHoc(IdBaiHoc)
        ON DELETE CASCADE
);
GO

CREATE NONCLUSTERED INDEX IX_TaiLieu_IdBaiHoc
    ON dbo.TaiLieu(IdBaiHoc);
GO

IF OBJECT_ID('dbo.spTaiLieu_Them', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spTaiLieu_Them;
GO

CREATE PROCEDURE dbo.spTaiLieu_Them
    @IdBaiHoc INT,
    @URL NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.BaiHoc WHERE IdBaiHoc = @IdBaiHoc)
    BEGIN
        RAISERROR(N'Bài học không tồn tại!', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO dbo.TaiLieu (IdBaiHoc, URL)
        VALUES (@IdBaiHoc, @URL);

        COMMIT TRANSACTION;
        SELECT N'Thêm tài liệu thành công!' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        RAISERROR(N'Lỗi khi thêm tài liệu!', 16, 1);
    END CATCH
END;
GO

IF OBJECT_ID('dbo.spTaiLieu_Xoa', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spTaiLieu_Xoa;
GO

CREATE PROCEDURE dbo.spTaiLieu_Xoa
    @IdTaiLieu INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.TaiLieu WHERE IdTaiLieu = @IdTaiLieu)
    BEGIN
        RAISERROR(N'Tài liệu không tồn tại!', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM dbo.TaiLieu
        WHERE IdTaiLieu = @IdTaiLieu;

        COMMIT TRANSACTION;
        SELECT N'Xóa tài liệu thành công!' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        RAISERROR(N'Lỗi khi xóa tài liệu!', 16, 1);
    END CATCH
END;
GO
