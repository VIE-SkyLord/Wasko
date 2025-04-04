USE Wasko;
GO
DROP PROCEDURE IF EXISTS sp_CopyKhoaHoc;
GO
CREATE PROCEDURE sp_CopyKhoaHoc
    @IdKhoaHoc INT  -- Id của khóa học gốc cần sao chép
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Kiểm tra khóa học gốc có tồn tại hay không
    IF NOT EXISTS(SELECT 1 FROM KhoaHoc WHERE IdKhoaHoc = @IdKhoaHoc)
    BEGIN
        RAISERROR('Khóa học gốc không tồn tại.', 16, 1);
        RETURN;
    END

    -- Chèn bản sao của khóa học, lưu lại Id của khóa học gốc vào cột IdBanGoc.
    INSERT INTO KhoaHoc (
        IdBanGoc,
        IdGiangVien,
        TenKhoaHoc,
        TrangThai,
        MoTa,
        NgayXuatBan,
        IdNguoiDuyet,
        NgayDuyet,
        IdChuDe,
        SoLuongVideo,
        GiaKhoaHoc,
        SoSaoTrungBinh
    )
    SELECT 
        @IdKhoaHoc,                    -- Lưu Id của khóa học gốc
        IdGiangVien,
        TenKhoaHoc + N' (Bản sao)',     -- Sửa lại tên để phân biệt
        TrangThai,
        MoTa,
        NgayXuatBan,
        IdNguoiDuyet,
        NgayDuyet,
        IdChuDe,
        SoLuongVideo,
        GiaKhoaHoc,
        SoSaoTrungBinh
    FROM KhoaHoc
    WHERE IdKhoaHoc = @IdKhoaHoc;
    
    SELECT N'Bản sao của khóa học đã được tạo thành công!' AS Message;
END;
GO

EXEC sp_CopyKhoaHoc @IdKhoaHoc = 1;
SELECT * FROM KhoaHoc

DROP PROCEDURE IF EXISTS sp_SuaBanSaoKhoaHoc;
GO
CREATE PROCEDURE sp_SuaBanSaoKhoaHoc
    @IdKhoaHoc INT,                     -- Id của bản sao khóa học cần sửa
    @TenKhoaHoc NVARCHAR(255) = NULL,     -- Tên khóa học (nếu muốn cập nhật)
    @MoTa NVARCHAR(MAX) = NULL,           -- Mô tả (nếu muốn cập nhật)
    @TrangThai NVARCHAR(50) = N'Đã thu hồi',       -- Trạng thái (nếu muốn cập nhật)
    @NgayXuatBan DATE = NULL,             -- Ngày xuất bản (nếu muốn cập nhật)
    @GiaKhoaHoc INT = NULL                -- Giá khóa học (nếu muốn cập nhật)
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra xem khóa học có tồn tại không
    IF NOT EXISTS(SELECT 1 FROM KhoaHoc WHERE IdKhoaHoc = @IdKhoaHoc)
    BEGIN
        RAISERROR('Khóa học không tồn tại.', 16, 1);
        RETURN;
    END

    -- Cập nhật các trường nếu tham số không NULL
    UPDATE KhoaHoc
    SET 
        TenKhoaHoc = ISNULL(@TenKhoaHoc, TenKhoaHoc),
        MoTa = ISNULL(@MoTa, MoTa),
        TrangThai = ISNULL(@TrangThai, TrangThai),
        NgayXuatBan = ISNULL(@NgayXuatBan, NgayXuatBan),
        GiaKhoaHoc = ISNULL(@GiaKhoaHoc, GiaKhoaHoc)
    WHERE IdKhoaHoc = @IdKhoaHoc;
    
    SELECT 'Cập nhật bản sao khóa học thành công!' AS Message;
END;
GO

EXEC sp_SuaBanSaoKhoaHoc @IdKhoaHoc = 2,@TenKhoaHoc=N'Bản sao',@MoTa=NULL,@TrangThai=N'Đã thu hồi',@NgayXuatBan=NULL,@GiaKhoaHoc=NULL;

DROP PROCEDURE IF EXISTS sp_GhiDeVaXoaBanSaoKhoaHoc;
GO

CREATE PROCEDURE sp_GhiDeVaXoaBanSaoKhoaHoc
    @IdKhoaHoc_Copy INT  -- Id của bản sao khóa học cần ghi đè lên gốc
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @IdKhoaHoc_Goc INT;
    
    -- Kiểm tra xem bản sao có tồn tại không
    IF NOT EXISTS(SELECT 1 FROM KhoaHoc WHERE IdKhoaHoc = @IdKhoaHoc_Copy)
    BEGIN
        RAISERROR('Bản sao không tồn tại.', 16, 1);
        RETURN;
    END
    
    -- Lấy Id của khóa học gốc từ bản sao
    SELECT @IdKhoaHoc_Goc = IdBanGoc FROM KhoaHoc WHERE IdKhoaHoc = @IdKhoaHoc_Copy;
    
    IF @IdKhoaHoc_Goc IS NULL
    BEGIN
        RAISERROR('Bản sao không có thông tin khóa học gốc (IdBanGoc is NULL).', 16, 1);
        RETURN;
    END
    
    -- Kiểm tra khóa học gốc có tồn tại không
    IF NOT EXISTS(SELECT 1 FROM KhoaHoc WHERE IdKhoaHoc = @IdKhoaHoc_Goc)
    BEGIN
        RAISERROR('Khóa học gốc không tồn tại.', 16, 1);
        RETURN;
    END

    -- Ghi đè thông tin từ bản sao lên khóa học gốc
    UPDATE KhoaHoc
    SET 
        TenKhoaHoc = CopyData.TenKhoaHoc,
        MoTa = CopyData.MoTa,
        TrangThai = CopyData.TrangThai,
        NgayXuatBan = CopyData.NgayXuatBan,
        IdNguoiDuyet = CopyData.IdNguoiDuyet,
        NgayDuyet = CopyData.NgayDuyet,
        IdChuDe = CopyData.IdChuDe,
        SoLuongVideo = CopyData.SoLuongVideo,
        GiaKhoaHoc = CopyData.GiaKhoaHoc,
        SoSaoTrungBinh = CopyData.SoSaoTrungBinh
    FROM KhoaHoc AS Goc
    CROSS APPLY (
        SELECT 
            TenKhoaHoc,
            MoTa,
            TrangThai,
            NgayXuatBan,
            IdNguoiDuyet,
            NgayDuyet,
            IdChuDe,
            SoLuongVideo,
            GiaKhoaHoc,
            SoSaoTrungBinh
        FROM KhoaHoc
        WHERE IdKhoaHoc = @IdKhoaHoc_Copy
    ) AS CopyData
    WHERE Goc.IdKhoaHoc = @IdKhoaHoc_Goc;
    
    -- Xóa bản sao sau khi đã ghi đè thông tin
    DELETE FROM KhoaHoc WHERE IdKhoaHoc = @IdKhoaHoc_Copy;
    
    SELECT 'Ghi đè khóa học gốc và xóa bản sao thành công!' AS Message;
END;
GO

EXEC sp_GhiDeVaXoaBanSaoKhoaHoc @IdKhoaHoc_Copy = 2

INSERT INTO KhoaHoc (
    IdBanGoc,        -- Với khóa học gốc, IdBanGoc có thể để NULL
    IdGiangVien,     -- Giả sử giá trị 1 đã tồn tại trong bảng NguoiDung làm giảng viên
    TenKhoaHoc, 
    TrangThai, 
    MoTa, 
    NgayTao,         -- Sử dụng giá trị mặc định nếu muốn
    GiaKhoaHoc
)
VALUES (
    NULL,            -- Khóa học gốc không có Id bản gốc (IdBanGoc)
    1,               -- Giả sử IdGiangVien = 1 (đảm bảo tồn tại trong bảng NguoiDung)
    N'Khóa học gốc', 
    N'Đã tạo', 
    N'Mô tả khóa học gốc', 
    GETDATE(),       -- Ngày tạo hiện tại
    100000           -- Giá khóa học, ví dụ 100,000
);
SELECT * FROM KhoaHoc