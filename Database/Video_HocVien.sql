-- Xóa bảng nếu đã tồn tại
IF OBJECT_ID('dbo.Video_HocVien', 'U') IS NOT NULL
    DROP TABLE dbo.Video_HocVien;
GO

CREATE TABLE dbo.Video_HocVien
(
    IdTK INT NOT NULL,           -- Tham chiếu HocVien(IdTK)
    IdVideo INT NOT NULL,        -- Tham chiếu Video(IdVideo)
    TrangThai NVARCHAR(50) NOT NULL,  -- 'chua_xem', 'da_xem'
    NgayCapNhat DATETIME NOT NULL DEFAULT(GETDATE()),

    CONSTRAINT PK_Video_HocVien
        PRIMARY KEY (IdTK, IdVideo),

    -- Chỉnh lại thành dbo.HocVien, và tham chiếu cột IdTK
    CONSTRAINT FK_Video_HocVien_HocVien
        FOREIGN KEY (IdTK)
        REFERENCES dbo.HocVien(IdTK)
        ON DELETE CASCADE,

    -- Tham chiếu đúng bảng dbo.Video, cột IdVideo
    CONSTRAINT FK_Video_HocVien_Video
        FOREIGN KEY (IdVideo)
        REFERENCES dbo.Video(IdVideo)
        ON DELETE NO ACTION
);
GO

-- Xóa thủ tục nếu đã tồn tại
IF OBJECT_ID('dbo.spVideoHocVien_DanhDauDaXem', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spVideoHocVien_DanhDauDaXem;
GO

-- Tạo thủ tục đánh dấu video là đã xem
CREATE PROCEDURE dbo.spVideoHocVien_DanhDauDaXem
    @IdTK INT,       -- Trùng với tên cột bên trên
    @IdVideo INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra tồn tại học viên
    IF NOT EXISTS (SELECT 1 FROM dbo.HocVien WHERE IdTK = @IdTK)
    BEGIN
        RAISERROR(N'Học viên (IdTK) không tồn tại!', 16, 1);
        RETURN;
    END

    -- Kiểm tra tồn tại video
    IF NOT EXISTS (SELECT 1 FROM dbo.Video WHERE IdVideo = @IdVideo)
    BEGIN
        RAISERROR(N'Video không tồn tại!', 16, 1);
        RETURN;
    END

    -- Kiểm tra cặp (IdTK, IdVideo) đã có chưa
    IF NOT EXISTS (
        SELECT 1 
        FROM dbo.Video_HocVien
        WHERE IdTK = @IdTK 
          AND IdVideo = @IdVideo
    )
    BEGIN
        -- Chưa có => chèn mới
        INSERT INTO dbo.Video_HocVien (IdTK, IdVideo, TrangThai)
        VALUES (@IdTK, @IdVideo, N'da_xem');

        SELECT N'Đã đánh dấu video là đã xem (thêm mới)!' AS Message;
    END
    ELSE
    BEGIN
        -- Đã có => update trạng thái
        UPDATE dbo.Video_HocVien
        SET TrangThai = N'da_xem',
            NgayCapNhat = GETDATE()
        WHERE IdTK = @IdTK
          AND IdVideo = @IdVideo;

        SELECT N'Đã đánh dấu video là đã xem (cập nhật)!' AS Message;
    END
END;
GO
