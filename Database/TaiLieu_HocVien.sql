-- Xóa bảng nếu tồn tại
IF OBJECT_ID('dbo.TaiLieu_HocVien', 'U') IS NOT NULL
    DROP TABLE dbo.TaiLieu_HocVien;
GO

CREATE TABLE dbo.TaiLieu_HocVien
(
    IdHocVien INT NOT NULL,            -- Tham chiếu đến bảng HocVien (PK: IdTK)
    IdTaiLieu INT NOT NULL,            -- Tham chiếu đến bảng TaiLieu
    TrangThai NVARCHAR(50) NOT NULL,   -- 'chua_doc', 'da_doc'
    NgayCapNhat DATETIME NOT NULL DEFAULT(GETDATE()),

    CONSTRAINT PK_TaiLieu_HocVien
        PRIMARY KEY (IdHocVien, IdTaiLieu),

    CONSTRAINT FK_TaiLieu_HocVien_HocVien
        FOREIGN KEY (IdHocVien)
        REFERENCES dbo.HocVien(IdTK)  -- Sửa thành dbo.HocVien(IdTK)
        ON DELETE CASCADE,

    CONSTRAINT FK_TaiLieu_HocVien_TaiLieu
        FOREIGN KEY (IdTaiLieu)
        REFERENCES dbo.TaiLieu(IdTaiLieu)
        ON DELETE NO ACTION
);
GO

-- Xóa Stored Procedure nếu tồn tại
IF OBJECT_ID('dbo.spTaiLieuHocVien_DanhDauDaDoc', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spTaiLieuHocVien_DanhDauDaDoc;
GO

CREATE PROCEDURE dbo.spTaiLieuHocVien_DanhDauDaDoc
    @IdHocVien INT,
    @IdTaiLieu INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra tồn tại của học viên dựa trên cột IdTK trong bảng HocVien
    IF NOT EXISTS (SELECT 1 FROM dbo.HocVien WHERE IdTK = @IdHocVien)
    BEGIN
        RAISERROR(N'Học viên không tồn tại!', 16, 1);
        RETURN;
    END

    -- Kiểm tra tồn tại của tài liệu
    IF NOT EXISTS (SELECT 1 FROM dbo.TaiLieu WHERE IdTaiLieu = @IdTaiLieu)
    BEGIN
        RAISERROR(N'Tài liệu không tồn tại!', 16, 1);
        RETURN;
    END

    -- Kiểm tra xem cặp (IdHocVien, IdTaiLieu) đã tồn tại trong bảng TaiLieu_HocVien chưa
    IF NOT EXISTS (
        SELECT 1 FROM dbo.TaiLieu_HocVien
        WHERE IdHocVien = @IdHocVien AND IdTaiLieu = @IdTaiLieu
    )
    BEGIN
        -- Nếu chưa có, chèn mới
        INSERT INTO dbo.TaiLieu_HocVien (IdHocVien, IdTaiLieu, TrangThai)
        VALUES (@IdHocVien, @IdTaiLieu, N'da_doc');
        SELECT N'Đã đánh dấu tài liệu là đã đọc (thêm mới)!' AS Message;
    END
    ELSE
    BEGIN
        -- Nếu đã có, cập nhật trạng thái
        UPDATE dbo.TaiLieu_HocVien
        SET TrangThai = N'da_doc',
            NgayCapNhat = GETDATE()
        WHERE IdHocVien = @IdHocVien
          AND IdTaiLieu = @IdTaiLieu;
        SELECT N'Đã đánh dấu tài liệu là đã đọc (cập nhật)!' AS Message;
    END
END;
GO