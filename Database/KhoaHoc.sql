IF OBJECT_ID('dbo.KhoaHoc', 'U') IS NOT NULL
    DROP TABLE dbo.KhoaHoc;
GO

CREATE TABLE dbo.KhoaHoc
(
    IdKhoaHoc INT IDENTITY(1,1) PRIMARY KEY,
    TrangThai NVARCHAR(50) NOT NULL,    -- 'da_tao','cho_duyet','da_xuat_ban','da_duyet','an_khoa_hoc', ...
    
    IdGiangVien INT NOT NULL,          -- Tham chiếu giảng viên
    TenKhoaHoc NVARCHAR(200) NOT NULL,
    MoTa NVARCHAR(MAX) NULL,
    NgayTao DATETIME NOT NULL DEFAULT(GETDATE()),
    NgayXuatBan DATETIME NULL,
    IdNguoiDuyet INT NULL,
    NgayDuyet DATETIME NULL,
    NgayAn DATETIME NULL,

    IdChuDe INT NULL,  -- chủ đề (tham chiếu sang DMChuDe)
    IdCapDo INT NOT NULL,  -- cấp độ (tham chiếu sang DMCapDo)

    ThoiLuong INT NULL,
    SoVideo INT NULL,
    GiaKhoaHoc DECIMAL(18,2) NULL,
    SoSaoTrungBinh DECIMAL(3,2) NULL,
    NoiDungDanhGia NVARCHAR(MAX) NULL,
    ThongBao NVARCHAR(MAX) NULL,

    -- Khóa ngoại đến GiangVien
    CONSTRAINT FK_KhoaHoc_GiangVien
        FOREIGN KEY (IdGiangVien) REFERENCES dbo.GiangVien(IdTK)
        ON DELETE CASCADE,  -- hoặc RESTRICT, tuỳ nhu cầu

    -- Khóa ngoại đến DMChuDe
    CONSTRAINT FK_KhoaHoc_DMChuDe
        FOREIGN KEY (IdChuDe) REFERENCES dbo.DMChuDe(IdChuDe)
        ON DELETE SET NULL,  -- Hoặc CASCADE, tuỳ ý

    -- Khóa ngoại đến DMCapDo
    CONSTRAINT FK_KhoaHoc_DMCapDo
        FOREIGN KEY (IdCapDo) REFERENCES dbo.DMCapDo(IdCapDo)
        ON DELETE CASCADE
);
GO

-- Tạo Index cho các khóa ngoại (giúp truy vấn nhanh hơn)
CREATE NONCLUSTERED INDEX IX_KhoaHoc_IdGiangVien ON dbo.KhoaHoc(IdGiangVien);
CREATE NONCLUSTERED INDEX IX_KhoaHoc_IdChuDe ON dbo.KhoaHoc(IdChuDe);
CREATE NONCLUSTERED INDEX IX_KhoaHoc_IdCapDo ON dbo.KhoaHoc(IdCapDo);
GO


CREATE PROCEDURE sp_KhoaHoc_Them
    @CallerId INT,
    @IdGiangVien INT,
    @TenKhoaHoc NVARCHAR(200),
    @MoTa NVARCHAR(MAX) = NULL,
    @IdChuDe INT = NULL,               -- có thể NULL
    @IdCapDo INT,                      -- KHÔNG được để trống
    @ThoiLuong INT = NULL,
    @SoVideo INT = NULL,
    @GiaKhoaHoc DECIMAL(18,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Kiểm tra quyền => tuỳ bạn, ví dụ giảng viên, quản trị
    IF NOT EXISTS (
        SELECT 1 FROM TaiKhoan
        WHERE IdTK = @CallerId
          AND (VaiTro = 'GiangVien' OR VaiTro = 'QuanTriVien' OR VaiTro = 'QuanLyCapCao')
    )
    BEGIN
        RAISERROR(N'Bạn không có quyền tạo khóa học!', 16, 1);
        RETURN;
    END

    -- 2. Kiểm tra IdCapDo (KHÔNG được để trống)
    IF NOT EXISTS (SELECT 1 FROM DMCapDo WHERE IdCapDo = @IdCapDo)
    BEGIN
        RAISERROR(N'Cấp độ không tồn tại hoặc không được để trống!', 16, 1);
        RETURN;
    END

    -- 3. Nếu @IdChuDe = NULL => gán bằng IdChuDe của "Khóa học khác"
    IF @IdChuDe IS NULL
    BEGIN
        -- Giả sử row "Khóa học khác" có IdChuDe=1
        SET @IdChuDe = 1;
    END

    -- 4. Kiểm tra IdChuDe có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM DMChuDe WHERE IdChuDe = @IdChuDe)
    BEGIN
        RAISERROR(N'Chủ đề không tồn tại!', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO KhoaHoc(
            TrangThai,
            IdGiangVien,
            TenKhoaHoc,
            MoTa,
            IdChuDe,
            IdCapDo,
            ThoiLuong,
            SoVideo,
            GiaKhoaHoc
        )
        VALUES(
            N'da_tao',       -- Mặc định mới tạo
            @IdGiangVien,
            @TenKhoaHoc,
            @MoTa,
            @IdChuDe,
            @IdCapDo,
            @ThoiLuong,
            @SoVideo,
            @GiaKhoaHoc
        );

        COMMIT TRANSACTION;
        SELECT N'Tạo khóa học thành công!' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        RAISERROR('Lỗi không xác định', 16, 1);
    END CATCH
END
GO

CREATE PROCEDURE sp_KhoaHoc_Sua
    @CallerId INT,
    @IdKhoaHoc INT,
    @TenKhoaHoc NVARCHAR(200),
    @MoTa NVARCHAR(MAX) = NULL,
    @IdChuDe INT,
    @IdCapDo INT,
    @ThoiLuong INT = NULL,
    @SoVideo INT = NULL,
    @GiaKhoaHoc DECIMAL(18,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Tìm IdGiangVien, ...
    DECLARE @IdGv INT;
    SELECT @IdGv = IdGiangVien
    FROM KhoaHoc
    WHERE IdKhoaHoc = @IdKhoaHoc;

    IF @IdGv IS NULL
    BEGIN
        RAISERROR(N'Không tìm thấy khóa học!', 16, 1);
        RETURN;
    END

    -- 2. Kiểm tra xem @CallerId có phải chính giảng viên tạo ra, hoặc là quản trị
    DECLARE @VaiTro NVARCHAR(50);
    SELECT @VaiTro = VaiTro
    FROM TaiKhoan
    WHERE IdTK = @CallerId;

    IF @VaiTro IS NULL
    BEGIN
        RAISERROR(N'Tài khoản không hợp lệ!', 16, 1);
        RETURN;
    END

    IF @VaiTro NOT IN ('QuanTriVien','QuanLyCapCao')
       AND @CallerId <> @IdGv
    BEGIN
        RAISERROR(N'Bạn không có quyền sửa khóa học này!', 16, 1);
        RETURN;
    END

    -- 3. Kiểm tra chủ đề, cấp độ
    IF NOT EXISTS (SELECT 1 FROM DMChuDe WHERE IdChuDe = @IdChuDe)
    BEGIN
        RAISERROR(N'Chủ đề không tồn tại!', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM DMCapDo WHERE IdCapDo = @IdCapDo)
    BEGIN
        RAISERROR(N'Cấp độ không tồn tại!', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE KhoaHoc
        SET TenKhoaHoc = @TenKhoaHoc,
            MoTa = @MoTa,
            IdChuDe = @IdChuDe,
            IdCapDo = @IdCapDo,
            ThoiLuong = @ThoiLuong,
            SoVideo = @SoVideo,
            GiaKhoaHoc = @GiaKhoaHoc
        WHERE IdKhoaHoc = @IdKhoaHoc;

        COMMIT TRANSACTION;
        SELECT N'Sửa khóa học thành công!' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        RAISERROR('Lỗi không xác định', 16, 1);
    END CATCH
END
GO

CREATE PROCEDURE sp_KhoaHoc_XuatBan
    @CallerId INT,
    @IdKhoaHoc INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Kiểm tra quyền
    DECLARE @VaiTro NVARCHAR(50);
    SELECT @VaiTro = VaiTro
    FROM TaiKhoan
    WHERE IdTK = @CallerId;

    IF @VaiTro NOT IN ('QuanTriVien','QuanLyCapCao')
    BEGIN
        RAISERROR(N'Bạn không có quyền xuất bản khóa học!', 16, 1);
        RETURN;
    END

    -- 2. Kiểm tra tồn tại
    IF NOT EXISTS (SELECT 1 FROM KhoaHoc WHERE IdKhoaHoc = @IdKhoaHoc)
    BEGIN
        RAISERROR(N'Không tìm thấy khóa học!', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE KhoaHoc
        SET TrangThai = N'da_xuat_ban',
            IdNguoiDuyet = @CallerId,
            NgayDuyet = GETDATE(),
            NgayXuatBan = GETDATE()
        WHERE IdKhoaHoc = @IdKhoaHoc;

        COMMIT TRANSACTION;
        SELECT N'Khóa học đã được xuất bản!' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        RAISERROR('Lỗi không xác định', 16, 1);
    END CATCH
END
GO

CREATE PROCEDURE sp_KhoaHoc_An
    @CallerId INT,
    @IdKhoaHoc INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra quyền
    DECLARE @VaiTro NVARCHAR(50);
    SELECT @VaiTro = VaiTro
    FROM TaiKhoan
    WHERE IdTK = @CallerId;

    IF @VaiTro NOT IN ('QuanTriVien','QuanLyCapCao')
    BEGIN
        RAISERROR(N'Bạn không có quyền ẩn khóa học!', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM KhoaHoc WHERE IdKhoaHoc = @IdKhoaHoc)
    BEGIN
        RAISERROR(N'Không tìm thấy khóa học!', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE KhoaHoc
        SET TrangThai = N'an_khoa_hoc',
            NgayAn = GETDATE()
        WHERE IdKhoaHoc = @IdKhoaHoc;

        COMMIT TRANSACTION;
        SELECT N'Khóa học đã được ẩn!' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        RAISERROR('Lỗi không xác định', 16, 1);
    END CATCH
END
GO

CREATE PROCEDURE sp_KhoaHoc_Duyet
    @CallerId INT,
    @IdKhoaHoc INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Kiểm tra quyền
    DECLARE @VaiTro NVARCHAR(50);
    SELECT @VaiTro = VaiTro
    FROM TaiKhoan
    WHERE IdTK = @CallerId;

    IF @VaiTro NOT IN ('QuanTriVien','QuanLyCapCao')
    BEGIN
        RAISERROR(N'Bạn không có quyền duyệt khóa học!', 16, 1);
        RETURN;
    END

    -- 2. Kiểm tra tồn tại
    IF NOT EXISTS (SELECT 1 FROM KhoaHoc WHERE IdKhoaHoc = @IdKhoaHoc)
    BEGIN
        RAISERROR(N'Không tìm thấy khóa học!', 16, 1);
        RETURN;
    END

    -- 3. Cập nhật trạng thái => 'da_duyet'
    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE KhoaHoc
        SET TrangThai = N'da_duyet',
            IdNguoiDuyet = @CallerId,
            NgayDuyet = GETDATE()
        WHERE IdKhoaHoc = @IdKhoaHoc;

        COMMIT TRANSACTION;
        SELECT N'Khóa học đã được duyệt!' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        RAISERROR('Lỗi không xác định', 16, 1);
    END CATCH
END
GO
