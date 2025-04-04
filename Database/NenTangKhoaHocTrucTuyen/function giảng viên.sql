-- Stored Procedure: Tạo khóa học mới
CREATE PROCEDURE sp_TaoKhoaHoc
    @TieuDe NVARCHAR(200),
    @MoTa NVARCHAR(MAX),
    @Gia DECIMAL(18,2),
    @MaDanhMuc INT,
    @MaGiangVien INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        INSERT INTO KhoaHoc 
        (TieuDe, MoTa, Gia, MaDanhMuc, MaGiangVien, MaTrangThai)
        VALUES 
        (@TieuDe, @MoTa, @Gia, @MaDanhMuc, @MaGiangVien, 1); -- Trạng thái bản nháp

        SELECT SCOPE_IDENTITY() AS MaKhoaHoc;
    END TRY
    BEGIN CATCH
        RAISERROR('Lỗi tạo khóa học', 16, 1);
    END CATCH
END
GO

-- Function: Tính phần trăm hoàn thành khóa học
CREATE FUNCTION fn_TinhPhanTramHoanThanhKhoaHoc
(
    @MaHocVien INT, 
    @MaKhoaHoc INT
)
RETURNS DECIMAL(5,2)
AS
BEGIN
    DECLARE @TongSoBaiHoc INT, @SoBaiHocHoanThanh INT, @PhanTramHoanThanh DECIMAL(5,2);

    SELECT @TongSoBaiHoc = COUNT(*)
    FROM BaiHoc 
    WHERE MaKhoaHoc = @MaKhoaHoc;

    SELECT @SoBaiHocHoanThanh = COUNT(*)
    FROM TienDoBaiHoc
    WHERE MaHocVien = @MaHocVien 
    AND MaBaiHoc IN (SELECT MaBaiHoc FROM BaiHoc WHERE MaKhoaHoc = @MaKhoaHoc)
    AND DaHoanThanh = 1;

    SET @PhanTramHoanThanh = CASE 
        WHEN @TongSoBaiHoc > 0 
        THEN CAST((@SoBaiHocHoanThanh * 100.0 / @TongSoBaiHoc) AS DECIMAL(5,2))
        ELSE 0 
    END;

    RETURN @PhanTramHoanThanh;
END
GO

CREATE PROCEDURE sp_CapNhatKhoaHoc
    @MaKhoaHoc INT,
    @TieuDe NVARCHAR(200),
    @MoTa NVARCHAR(MAX),
    @Gia DECIMAL(18,2),          -- Giá chỉ được cập nhật nếu khóa học đã xuất bản
    @MaDanhMuc INT,
    @MaGiangVien INT,
    @ThanhCong BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Lấy trạng thái hiện tại của khóa học
        DECLARE @TrangThai INT;
        SELECT @TrangThai = MaTrangThai 
        FROM KhoaHoc 
        WHERE MaKhoaHoc = @MaKhoaHoc;

        IF @TrangThai IS NULL
        BEGIN
            RAISERROR('Không tìm thấy khóa học', 16, 1);
            SET @ThanhCong = 0;
            RETURN;
        END

        -- Nếu khóa học chưa xuất bản (trạng thái = 1: bản nháp)
        IF @TrangThai = 1
        BEGIN
            UPDATE KhoaHoc
            SET 
                TieuDe = @TieuDe,
                MoTa = @MoTa,
                MaDanhMuc = @MaDanhMuc,
                MaGiangVien = @MaGiangVien,
                NgayCapNhat = GETDATE()
                -- Không cập nhật Giá vì khóa học chưa xuất bản
            WHERE MaKhoaHoc = @MaKhoaHoc;
        END
        ELSE
        BEGIN
            -- Nếu khóa học đã xuất bản thì cập nhật đầy đủ thông tin
            UPDATE KhoaHoc
            SET 
                TieuDe = @TieuDe,
                MoTa = @MoTa,
                Gia = @Gia,
                MaDanhMuc = @MaDanhMuc,
                MaGiangVien = @MaGiangVien,
                NgayCapNhat = GETDATE()
            WHERE MaKhoaHoc = @MaKhoaHoc;
        END

        IF @@ROWCOUNT > 0
            SET @ThanhCong = 1;
        ELSE
            SET @ThanhCong = 0;
    END TRY
    BEGIN CATCH
        SET @ThanhCong = 0;
        RAISERROR('Lỗi cập nhật khóa học', 16, 1);
    END CATCH;
END;
GO

