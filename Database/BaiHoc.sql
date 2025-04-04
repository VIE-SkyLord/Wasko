IF OBJECT_ID('dbo.BaiHoc', 'U') IS NOT NULL
    DROP TABLE dbo.BaiHoc;
GO

CREATE TABLE dbo.BaiHoc
(                  
    IdBaiHoc INT IDENTITY(1,1) PRIMARY KEY,
    IdKhoaHoc INT NOT NULL,               -- Tham chiếu đến bảng KhoaHoc
    TenBaiHoc NVARCHAR(200) NOT NULL,
    MoTa NVARCHAR(MAX) NULL,

    CONSTRAINT FK_BaiHoc_KhoaHoc
        FOREIGN KEY (IdKhoaHoc)
        REFERENCES dbo.KhoaHoc(IdKhoaHoc)
        ON DELETE CASCADE  -- Hoặc RESTRICT/SET NULL tuỳ nhu cầu
);
GO

CREATE NONCLUSTERED INDEX IX_BaiHoc_IdKhoaHoc
    ON dbo.BaiHoc(IdKhoaHoc);
GO

IF OBJECT_ID('dbo.spAddBaiHoc', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spAddBaiHoc;
GO

CREATE PROCEDURE dbo.spAddBaiHoc
    @IdKhoaHoc INT,
    @TenBaiHoc NVARCHAR(200),
    @MoTa NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra xem KhoaHoc có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM dbo.KhoaHoc WHERE IdKhoaHoc = @IdKhoaHoc)
    BEGIN
        RAISERROR(N'Khóa học không tồn tại!', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO dbo.BaiHoc (IdKhoaHoc, TenBaiHoc, MoTa)
        VALUES (@IdKhoaHoc, @TenBaiHoc, @MoTa);

        COMMIT TRANSACTION;
        SELECT N'Thêm bài học thành công!' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        RAISERROR(N'Lỗi khi thêm bài học', 16, 1);
    END CATCH
END
GO

IF OBJECT_ID('dbo.spUpdateBaiHoc', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spUpdateBaiHoc;
GO

CREATE PROCEDURE dbo.spUpdateBaiHoc
    @IdBaiHoc INT,
    @TenBaiHoc NVARCHAR(200),
    @MoTa NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra bài học có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM dbo.BaiHoc WHERE IdBaiHoc = @IdBaiHoc)
    BEGIN
        RAISERROR(N'Bài học không tồn tại!', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE dbo.BaiHoc
        SET TenBaiHoc = @TenBaiHoc,
            MoTa      = @MoTa
        WHERE IdBaiHoc = @IdBaiHoc;

        COMMIT TRANSACTION;
        SELECT N'Sửa bài học thành công!' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        RAISERROR(N'Lỗi khi sửa bài học', 16, 1);
    END CATCH
END
GO

IF OBJECT_ID('dbo.spDeleteBaiHoc', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spDeleteBaiHoc;
GO

CREATE PROCEDURE dbo.spDeleteBaiHoc
    @IdBaiHoc INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra bài học có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM dbo.BaiHoc WHERE IdBaiHoc = @IdBaiHoc)
    BEGIN
        RAISERROR(N'Bài học không tồn tại!', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM dbo.BaiHoc
        WHERE IdBaiHoc = @IdBaiHoc;

        COMMIT TRANSACTION;
        SELECT N'Xóa bài học thành công!' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        RAISERROR(N'Lỗi khi xóa bài học', 16, 1);
    END CATCH
END
GO
