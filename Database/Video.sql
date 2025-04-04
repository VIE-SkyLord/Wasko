IF OBJECT_ID('dbo.Video', 'U') IS NOT NULL
    DROP TABLE dbo.Video;
GO

CREATE TABLE dbo.Video
(
    IdVideo INT IDENTITY(1,1) PRIMARY KEY,
    IdBaiHoc INT NOT NULL,           -- Khóa ngoại trỏ sang BaiHoc
    Thumbnail NVARCHAR(500) NULL,    -- đường dẫn/URL ảnh thumbnail
    URL NVARCHAR(500) NOT NULL,      -- đường dẫn video

    CONSTRAINT FK_Video_BaiHoc
        FOREIGN KEY (IdBaiHoc)
        REFERENCES dbo.BaiHoc(IdBaiHoc)
        ON DELETE CASCADE
);
GO

CREATE NONCLUSTERED INDEX IX_Video_IdBaiHoc
    ON dbo.Video(IdBaiHoc);
GO

IF OBJECT_ID('dbo.spVideo_Them', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spVideo_Them;
GO

CREATE PROCEDURE dbo.spVideo_Them
    @IdBaiHoc INT,
    @Thumbnail NVARCHAR(500) = NULL,
    @URL NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra xem Bài học có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM dbo.BaiHoc WHERE IdBaiHoc = @IdBaiHoc)
    BEGIN
        RAISERROR(N'Bài học không tồn tại!', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO dbo.Video (IdBaiHoc, Thumbnail, URL)
        VALUES (@IdBaiHoc, @Thumbnail, @URL);

        COMMIT TRANSACTION;
        SELECT N'Thêm video thành công!' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        RAISERROR(N'Lỗi khi thêm video!', 16, 1);
    END CATCH
END;
GO

IF OBJECT_ID('dbo.spVideo_Xoa', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spVideo_Xoa;
GO

CREATE PROCEDURE dbo.spVideo_Xoa
    @IdVideo INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Video WHERE IdVideo = @IdVideo)
    BEGIN
        RAISERROR(N'Video không tồn tại!', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM dbo.Video
        WHERE IdVideo = @IdVideo;

        COMMIT TRANSACTION;
        SELECT N'Xóa video thành công!' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        RAISERROR(N'Lỗi khi xóa video!', 16, 1);
    END CATCH
END;
GO
