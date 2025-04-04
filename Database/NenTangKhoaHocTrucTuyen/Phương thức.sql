

CREATE PROCEDURE sp_DangKyKhoaHoc
    @MaHocVien INT,
    @MaKhoaHoc INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Kiểm tra xem học viên đã đăng ký khóa học chưa
        IF EXISTS (SELECT 1 FROM DangKyKhoaHoc 
                   WHERE MaHocVien = @MaHocVien AND MaKhoaHoc = @MaKhoaHoc)
        BEGIN
            RAISERROR('Học viên đã đăng ký khóa học này', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Thêm vào bảng đăng ký khóa học
        INSERT INTO DangKyKhoaHoc (MaHocVien, MaKhoaHoc)
        VALUES (@MaHocVien, @MaKhoaHoc);

        -- Khởi tạo tiến độ khóa học
        INSERT INTO TienDoKhoaHoc (MaHocVien, MaKhoaHoc)
        VALUES (@MaHocVien, @MaKhoaHoc);

        COMMIT TRANSACTION;

        SELECT 1 AS ThanhCong;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        RAISERROR('Lỗi đăng ký khóa học', 16, 1);
    END CATCH
END
GO

-- Stored Procedure: Cập nhật tiến độ bài học
CREATE PROCEDURE sp_CapNhatTienDoBaiHoc
    @MaHocVien INT,
    @MaBaiHoc INT,
    @DaHoanThanh BIT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Kiểm tra hoặc tạo bản ghi tiến độ bài học
        IF NOT EXISTS (SELECT 1 FROM TienDoBaiHoc WHERE MaHocVien = @MaHocVien AND MaBaiHoc = @MaBaiHoc)
        BEGIN
            INSERT INTO TienDoBaiHoc (MaHocVien, MaBaiHoc, DaHoanThanh, NgayHoanThanh)
            VALUES (@MaHocVien, @MaBaiHoc, @DaHoanThanh, CASE WHEN @DaHoanThanh = 1 THEN GETDATE() ELSE NULL END);
        END
        ELSE
        BEGIN
            UPDATE TienDoBaiHoc
            SET DaHoanThanh = @DaHoanThanh,
                NgayHoanThanh = CASE WHEN @DaHoanThanh = 1 THEN GETDATE() ELSE NgayHoanThanh END
            WHERE MaHocVien = @MaHocVien AND MaBaiHoc = @MaBaiHoc;
        END

        SELECT 1 AS ThanhCong;
    END TRY
    BEGIN CATCH
        RAISERROR('Lỗi cập nhật tiến độ bài học', 16, 1);
    END CATCH
END
GO

CREATE FUNCTION fn_KiemTraDieuKienHoanThanhBaiHoc
(
    @MaHocVien INT, 
    @MaBaiHoc INT
)
RETURNS BIT
AS
BEGIN
    DECLARE @KetQua BIT = 0;
    DECLARE @MaLoaiHoanThanh INT, 
            @PhanTramTaiLieuYeuCau DECIMAL(5,2);

    -- Lấy thông tin điều kiện hoàn thành bài học từ bảng BaiHoc
    SELECT 
        @MaLoaiHoanThanh = MaLoaiHoanThanh, 
        @PhanTramTaiLieuYeuCau = PhanTramTaiLieuYeuCau
    FROM BaiHoc 
    WHERE MaBaiHoc = @MaBaiHoc;

    -- Nếu không tìm thấy thông tin điều kiện, trả về chưa hoàn thành
    IF @MaLoaiHoanThanh IS NULL
        RETURN 0;

    -- Tính trung bình phần trăm hoàn thành tài liệu; sử dụng ISNULL để xử lý NULL
    DECLARE @PhanTramTaiLieuHoanThanh DECIMAL(5,2) = 0;
    SELECT @PhanTramTaiLieuHoanThanh = ISNULL(AVG(PhanTramHoanThanh), 0)
    FROM TienDoTaiLieuHocTap 
    WHERE MaHocVien = @MaHocVien 
      AND MaTaiLieu IN (SELECT MaTaiLieu FROM TaiLieuHocTap WHERE MaBaiHoc = @MaBaiHoc);

    -- Lấy điểm bài kiểm tra và điểm đạt; nếu không có thì coi là 0
    DECLARE @DiemBaiKiemTra INT = 0, 
            @DiemDat INT = 0;
    SELECT @DiemBaiKiemTra = ISNULL(DiemSo, 0), 
           @DiemDat = ISNULL(DiemDat, 0)
    FROM KetQuaBaiKiemTra 
    JOIN BaiKiemTra ON KetQuaBaiKiemTra.MaBaiKiemTra = BaiKiemTra.MaBaiKiemTra
    WHERE MaHocVien = @MaHocVien 
      AND BaiKiemTra.MaBaiHoc = @MaBaiHoc;

    -- Xác định điều kiện hoàn thành dựa trên MaLoaiHoanThanh:
    -- 1: Dựa trên bài kiểm tra, 2: Dựa trên tài liệu, 3: Cả hai
    SET @KetQua = CASE 
        WHEN @MaLoaiHoanThanh = 1 AND @DiemBaiKiemTra >= @DiemDat THEN 1
        WHEN @MaLoaiHoanThanh = 2 AND @PhanTramTaiLieuHoanThanh >= @PhanTramTaiLieuYeuCau THEN 1
        WHEN @MaLoaiHoanThanh = 3 
             AND @DiemBaiKiemTra >= @DiemDat 
             AND @PhanTramTaiLieuHoanThanh >= @PhanTramTaiLieuYeuCau THEN 1
        ELSE 0
    END;

    RETURN @KetQua;
END;
GO
