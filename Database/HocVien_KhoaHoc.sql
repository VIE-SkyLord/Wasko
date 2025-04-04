IF OBJECT_ID('dbo.HocVien_KhoaHoc', 'U') IS NOT NULL
    DROP TABLE dbo.HocVien_KhoaHoc;
GO

CREATE TABLE dbo.HocVien_KhoaHoc
(
    IdTK INT NOT NULL,          -- Tham chiếu HocVien(IdTK)
    IdKhoaHoc INT NOT NULL,          -- Tham chiếu KhoaHoc(IdKhoaHoc)
    
    TrangThai NVARCHAR(50) NOT NULL, -- 'gio_hang' | 'da_mua'
    NgayCapNhat DATETIME NOT NULL DEFAULT(GETDATE()),

    SoSao DECIMAL(3,2) NULL,         -- Đánh giá sao (VD: 4.5)
    BinhLuan NVARCHAR(MAX) NULL,     -- Nội dung bình luận
    DaNhanChungChi BIT NOT NULL DEFAULT(0),  -- 0: chưa nhận, 1: đã nhận
    
    CONSTRAINT PK_HocVien_KhoaHoc
        PRIMARY KEY (IdTK, IdKhoaHoc),

    CONSTRAINT FK_HocVien_KhoaHoc_HocVien
        FOREIGN KEY (IdTK)
        REFERENCES dbo.HocVien(IdTK)
        ON DELETE CASCADE,

    CONSTRAINT FK_HocVien_KhoaHoc_KhoaHoc
        FOREIGN KEY (IdKhoaHoc)
        REFERENCES dbo.KhoaHoc(IdKhoaHoc)
        ON DELETE NO ACTION
);
GO

IF OBJECT_ID('dbo.spHocVienKhoaHoc_ThemVaoGio', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spHocVienKhoaHoc_ThemVaoGio;
GO

CREATE PROCEDURE dbo.spHocVienKhoaHoc_ThemVaoGio
    @IdTK INT,
    @IdKhoaHoc INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra học viên, khóa học tồn tại
    IF NOT EXISTS (SELECT 1 FROM dbo.HocVien WHERE IdTK = @IdTK)
    BEGIN
        RAISERROR(N'Học viên không tồn tại!', 16, 1);
        RETURN;
    END
    IF NOT EXISTS (SELECT 1 FROM dbo.KhoaHoc WHERE IdKhoaHoc = @IdKhoaHoc)
    BEGIN
        RAISERROR(N'Khóa học không tồn tại!', 16, 1);
        RETURN;
    END

    -- Kiểm tra cặp (IdTK, IdKhoaHoc)
    IF EXISTS (SELECT 1 FROM dbo.HocVien_KhoaHoc
               WHERE IdTK = @IdTK AND IdKhoaHoc = @IdKhoaHoc)
    BEGIN
        DECLARE @TrangThai NVARCHAR(50);
        SELECT @TrangThai = TrangThai
        FROM dbo.HocVien_KhoaHoc
        WHERE IdTK = @IdTK AND IdKhoaHoc = @IdKhoaHoc;

        IF @TrangThai = N'da_mua'
        BEGIN
            RAISERROR(N'Khóa học đã được mua, không thể thêm vào giỏ!', 16, 1);
            RETURN;
        END
        ELSE
        BEGIN
            SELECT N'Khóa học đã có trong giỏ hàng!' AS Message;
            RETURN;
        END
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO dbo.HocVien_KhoaHoc (IdTK, IdKhoaHoc, TrangThai)
        VALUES (@IdTK, @IdKhoaHoc, N'gio_hang');

        COMMIT TRANSACTION;
        SELECT N'Khóa học đã được thêm vào giỏ hàng!' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        RAISERROR(N'Lỗi khi thêm khóa học vào giỏ hàng!', 16, 1);
    END CATCH
END;
GO

IF OBJECT_ID('dbo.spHocVienKhoaHoc_XoaKhoiGio', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spHocVienKhoaHoc_XoaKhoiGio;
GO

CREATE PROCEDURE dbo.spHocVienKhoaHoc_XoaKhoiGio
    @IdTK INT,
    @IdKhoaHoc INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.HocVien_KhoaHoc
                   WHERE IdTK = @IdTK
                     AND IdKhoaHoc = @IdKhoaHoc)
    BEGIN
        RAISERROR(N'Không tìm thấy khóa học trong giỏ!', 16, 1);
        RETURN;
    END

    DECLARE @TrangThai NVARCHAR(50);
    SELECT @TrangThai = TrangThai
    FROM dbo.HocVien_KhoaHoc
    WHERE IdTK = @IdTK AND IdKhoaHoc = @IdKhoaHoc;

    IF @TrangThai = N'da_mua'
    BEGIN
        RAISERROR(N'Khóa học đã mua, không thể xóa khỏi giỏ!', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM dbo.HocVien_KhoaHoc
        WHERE IdTK = @IdTK AND IdKhoaHoc = @IdKhoaHoc;

        COMMIT TRANSACTION;
        SELECT N'Xóa khóa học khỏi giỏ hàng thành công!' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        RAISERROR(N'Lỗi khi xóa khỏi giỏ hàng!', 16, 1);
    END CATCH
END;
GO

IF OBJECT_ID('dbo.spHocVienKhoaHoc_Mua', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spHocVienKhoaHoc_Mua;
GO

CREATE PROCEDURE dbo.spHocVienKhoaHoc_Mua
    @IdTK INT,
    @IdKhoaHoc INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.HocVien WHERE IdTK = @IdTK)
    BEGIN
        RAISERROR(N'Học viên không tồn tại!', 16, 1);
        RETURN;
    END
    IF NOT EXISTS (SELECT 1 FROM dbo.KhoaHoc WHERE IdKhoaHoc = @IdKhoaHoc)
    BEGIN
        RAISERROR(N'Khóa học không tồn tại!', 16, 1);
        RETURN;
    END

    -- Nếu chưa có record => chèn mới với 'da_mua'
    IF NOT EXISTS (SELECT 1 FROM dbo.HocVien_KhoaHoc
                   WHERE IdTK = @IdTK AND IdKhoaHoc = @IdKhoaHoc)
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;

            INSERT INTO dbo.HocVien_KhoaHoc (IdTK, IdKhoaHoc, TrangThai)
            VALUES (@IdTK, @IdKhoaHoc, N'da_mua');

            COMMIT TRANSACTION;
            SELECT N'Khóa học đã được mua thành công!' AS Message;
            RETURN;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            RAISERROR(N'Lỗi khi mua khóa học (thêm mới)!', 16, 1);
            RETURN;
        END CATCH
    END

    -- Nếu đã có => kiểm tra trạng thái
    DECLARE @TrangThai NVARCHAR(50);
    SELECT @TrangThai = TrangThai
    FROM dbo.HocVien_KhoaHoc
    WHERE IdTK = @IdTK AND IdKhoaHoc = @IdKhoaHoc;

    IF @TrangThai = N'da_mua'
    BEGIN
        SELECT N'Khóa học này đã được mua trước đó!' AS Message;
        RETURN;
    END

    -- Cập nhật từ 'gio_hang' -> 'da_mua'
    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE dbo.HocVien_KhoaHoc
        SET TrangThai = N'da_mua',
            NgayCapNhat = GETDATE()
        WHERE IdTK = @IdTK
          AND IdKhoaHoc = @IdKhoaHoc;

        COMMIT TRANSACTION;
        SELECT N'Mua khóa học thành công!' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        RAISERROR(N'Lỗi khi mua khóa học!', 16, 1);
    END CATCH
END;
GO

IF OBJECT_ID('dbo.spHocVienKhoaHoc_NhanChungChi', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spHocVienKhoaHoc_NhanChungChi;
GO

CREATE PROCEDURE dbo.spHocVienKhoaHoc_NhanChungChi
    @IdTK INT,       -- Mã học viên (đã tồn tại trong HocVien_KhoaHoc, sử dụng cột IdTK)
    @IdKhoaHoc INT   -- Mã khóa học (trong bảng KhoaHoc)
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra xem học viên đã mua khóa học chưa
    IF NOT EXISTS (
        SELECT 1
        FROM dbo.HocVien_KhoaHoc
        WHERE IdTK = @IdTK
          AND IdKhoaHoc = @IdKhoaHoc
          AND TrangThai = N'da_mua'
    )
    BEGIN
        RAISERROR(N'Học viên chưa mua khóa học này!', 16, 1);
        RETURN;
    END

    DECLARE @TotalQuiz INT, @PassedQuiz INT;

    -- Đếm tổng số quiz của khóa học bằng cách JOIN Quiz với BaiHoc (do Quiz lưu IdBaiHoc)
    SELECT @TotalQuiz = COUNT(*)
    FROM dbo.Quiz q
    JOIN dbo.BaiHoc b ON q.IdBaiHoc = b.IdBaiHoc
    WHERE b.IdKhoaHoc = @IdKhoaHoc;

    IF @TotalQuiz = 0
    BEGIN
        RAISERROR(N'Khóa học không có bài quiz nào!', 16, 1);
        RETURN;
    END

    -- Đếm số quiz mà học viên đã pass
    SELECT @PassedQuiz = COUNT(*)
    FROM dbo.KetQuaQuiz kq
    JOIN dbo.Quiz q ON kq.IdQuiz = q.IdQuiz
    JOIN dbo.BaiHoc b ON q.IdBaiHoc = b.IdBaiHoc
    WHERE b.IdKhoaHoc = @IdKhoaHoc
      AND kq.IdHocVien = @IdTK
      AND kq.IsPass = 1;

    IF @PassedQuiz < @TotalQuiz
    BEGIN
        RAISERROR(N'Học viên chưa pass hết quiz!', 16, 1);
        RETURN;
    END

    -- Kiểm tra xem học viên đã nhận chứng chỉ chưa
    IF EXISTS (
        SELECT 1
        FROM dbo.HocVien_KhoaHoc
        WHERE IdTK = @IdTK
          AND IdKhoaHoc = @IdKhoaHoc
          AND DaNhanChungChi = 1
    )
    BEGIN
        SELECT N'Học viên đã nhận chứng chỉ cho khóa học này!' AS Message;
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE dbo.HocVien_KhoaHoc
        SET DaNhanChungChi = 1,
            NgayCapNhat = GETDATE()
        WHERE IdTK = @IdTK
          AND IdKhoaHoc = @IdKhoaHoc;

        COMMIT TRANSACTION;
        SELECT N'Học viên đã nhận chứng chỉ!' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        RAISERROR(N'Lỗi khi nhận chứng chỉ!', 16, 1);
    END CATCH
END;
GO


IF OBJECT_ID('dbo.spHocVienKhoaHoc_DanhGia', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spHocVienKhoaHoc_DanhGia;
GO

CREATE PROCEDURE dbo.spHocVienKhoaHoc_DanhGia
    @IdTK INT,
    @IdKhoaHoc INT,
    @SoSao DECIMAL(3,2) = NULL,
    @BinhLuan NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- 1) Kiểm tra cặp (IdTK, IdKhoaHoc) tồn tại
    IF NOT EXISTS (SELECT 1 
                   FROM dbo.HocVien_KhoaHoc
                   WHERE IdTK = @IdTK
                     AND IdKhoaHoc = @IdKhoaHoc)
    BEGIN
        RAISERROR(N'Học viên chưa thêm/mua khóa học này!', 16, 1);
        RETURN;
    END

    -- 2) Chỉ cho phép đánh giá/bình luận khi TrangThai='da_mua'
    IF NOT EXISTS (
        SELECT 1 
        FROM dbo.HocVien_KhoaHoc
        WHERE IdTK = @IdTK
          AND IdKhoaHoc = @IdKhoaHoc
          AND TrangThai = N'da_mua'
    )
    BEGIN
        RAISERROR(N'Học viên chưa mua khóa học, không thể đánh giá!', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 3) Cập nhật SoSao và BinhLuan
        UPDATE dbo.HocVien_KhoaHoc
        SET SoSao = @SoSao,
            BinhLuan = @BinhLuan,
            NgayCapNhat = GETDATE()
        WHERE IdTK = @IdTK
          AND IdKhoaHoc = @IdKhoaHoc;

        COMMIT TRANSACTION;
        SELECT N'Cập nhật đánh giá, bình luận thành công!' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        RAISERROR(N'Lỗi khi đánh giá/bình luận!', 16, 1);
    END CATCH
END;
GO
