USE Wasko;
GO
--CẬP NHẬT CHỦ ĐỀ
--Thêm chủ đề
DROP PROCEDURE IF EXISTS sp_ThemChuDe;
GO
CREATE PROCEDURE sp_ThemChuDe
    @IdNguoiDung INT,  -- Người thực hiện thao tác
    @TenChuDe NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra xem người dùng có phải là Quản trị viên không
    IF NOT EXISTS (
        SELECT 1 FROM NguoiDung WHERE IdNguoiDung = @IdNguoiDung AND VaiTro = N'Quản trị viên'
    )
    BEGIN
        RAISERROR (N'Chỉ Quản trị viên mới có thể thêm chủ đề.', 16, 1);
        RETURN;
    END;

    -- Thêm chủ đề mới
    INSERT INTO ChuDe (TenChuDe) VALUES (@TenChuDe);

    -- Trả về ID của chủ đề vừa thêm
    DECLARE @IdChuDeMoi INT = SCOPE_IDENTITY();
    SELECT @IdChuDeMoi AS IdChuDe;
END;
GO
EXEC sp_ThemChuDe @IdNguoiDung = 1,@TenChuDe = N'Lập trình';
EXEC sp_ThemChuDe @IdNguoiDung = 1,@TenChuDe = N'Lập trình Python';
EXEC sp_ThemChuDe @IdNguoiDung = 1,@TenChuDe = N'Nấu ăn';
--Sửa chủ đề
DROP PROCEDURE IF EXISTS sp_SuaChuDe;
GO
CREATE PROCEDURE sp_SuaChuDe
    @IdNguoiDung INT,  -- Người thực hiện thao tác
    @IdChuDe INT,
    @TenChuDeMoi NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra quyền Quản trị viên
    IF NOT EXISTS (
        SELECT 1 FROM NguoiDung WHERE IdNguoiDung = @IdNguoiDung AND VaiTro = N'Quản trị viên'
    )
    BEGIN
        RAISERROR (N'Chỉ Quản trị viên mới có thể sửa chủ đề.', 16, 1);
        RETURN;
    END;

    -- Kiểm tra chủ đề có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM ChuDe WHERE IdChuDe = @IdChuDe)
    BEGIN
        RAISERROR (N'Chủ đề không tồn tại.', 16, 1);
        RETURN;
    END;

    -- Cập nhật chủ đề
    UPDATE ChuDe
    SET TenChuDe = @TenChuDeMoi
    WHERE IdChuDe = @IdChuDe;

    SELECT N'Chủ đề đã được cập nhật thành công.' AS Message;
END;
GO
EXEC sp_SuaChuDe @IdNguoiDung = 1,  @IdChuDe = 1,  @TenChuDeMoi = N'Cơ sở dữ liẹu';
--Xóa chủ đề
DROP PROCEDURE IF EXISTS sp_XoaChuDe;
GO
CREATE PROCEDURE sp_XoaChuDe
    @IdNguoiDung INT,  -- Người thực hiện thao tác
    @IdChuDe INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra quyền Quản trị viên
    IF NOT EXISTS (
        SELECT 1 FROM NguoiDung WHERE IdNguoiDung = @IdNguoiDung AND VaiTro = N'Quản trị viên'
    )
    BEGIN
        RAISERROR (N'Chỉ Quản trị viên mới có thể xóa chủ đề.', 16, 1);
        RETURN;
    END;

    -- Kiểm tra chủ đề có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM ChuDe WHERE IdChuDe = @IdChuDe)
    BEGIN
        RAISERROR (N'Chủ đề không tồn tại.', 16, 1);
        RETURN;
    END;

    -- Xóa chủ đề
    DELETE FROM ChuDe WHERE IdChuDe = @IdChuDe;

    SELECT N'Chủ đề đã được xóa thành công.' AS Message;
END;
GO
EXEC sp_XoaChuDe @IdNguoiDung = 1,  @IdChuDe = 3;

--CẬP NHẬT KHÓA HỌC
--Tạo khóa học
DROP PROCEDURE IF EXISTS sp_TaoKhoaHoc;
GO
CREATE PROCEDURE sp_TaoKhoaHoc
    @IdGiangVien INT,
    @TenKhoaHoc NVARCHAR(255),
    @MoTa NVARCHAR(MAX) = NULL,
    @IdChuDe INT = NULL,
	@CapDo NVARCHAR(50) = N'Trung cấp',
    @GiaKhoaHoc INT = 0
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra xem người dùng có phải là Giảng viên không
    IF NOT EXISTS (
        SELECT 1 
        FROM NguoiDung 
        WHERE IdNguoiDung = @IdGiangVien AND VaiTro = N'Giảng viên'
    )
    BEGIN
        RAISERROR (N'Chỉ giảng viên mới có thể tạo khóa học.', 16, 1);
        RETURN;
    END;

    -- Thêm khóa học mới
    INSERT INTO KhoaHoc (IdGiangVien, TenKhoaHoc, TrangThai, MoTa, NgayTao, IdChuDe, CapDo, GiaKhoaHoc)
    VALUES (@IdGiangVien, @TenKhoaHoc, N'Đã tạo', @MoTa, GETDATE(), @IdChuDe, @CapDo, @GiaKhoaHoc);
    
    -- Trả về ID của khóa học vừa tạo
    DECLARE @IdKhoaHocMoi INT = SCOPE_IDENTITY();
    SELECT @IdKhoaHocMoi AS IdKhoaHoc;
END;
GO
--SELECT * FROM KhoaHoc
EXEC sp_TaoKhoaHoc @IdGiangVien = 2,  @TenKhoaHoc = N'Lập trình SQL cơ bản',@MoTa = N'Khóa học hướng dẫn SQL từ cơ bản đến nâng cao',@IdChuDe = 1,@CapDo=N'Cơ bản',@GiaKhoaHoc = 500000;
EXEC sp_TaoKhoaHoc @IdGiangVien = 2,  @TenKhoaHoc = N'Lập trình Python',@MoTa = N'Khóa học hướng dẫn Python từ cơ bản đến nâng cao',@IdChuDe = 2,@CapDo=N'Người mới',@GiaKhoaHoc = 700000;

--Sửa khóa học
DROP PROCEDURE IF EXISTS sp_SuaKhoaHoc;
GO
CREATE PROCEDURE sp_SuaKhoaHoc
    @IdGiangVien INT,
    @IdKhoaHoc INT,
    @TenKhoaHocMoi NVARCHAR(255) = NULL,
    @MoTaMoi NVARCHAR(MAX) = NULL,
    @IdChuDeMoi INT = NULL,
    @CapDoMoi NVARCHAR(50) = NULL,
    @GiaKhoaHocMoi INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra xem khóa học có tồn tại, thuộc quyền sở hữu của giảng viên 
    -- và có trạng thái "Đã tạo" hoặc "Đã thu hồi"
    IF NOT EXISTS (
        SELECT 1 
        FROM KhoaHoc 
        WHERE IdKhoaHoc = @IdKhoaHoc 
        AND IdGiangVien = @IdGiangVien
        AND TrangThai IN (N'Đã tạo', N'Đã thu hồi')
    )
    BEGIN
        RAISERROR (N'Chỉ có thể chỉnh sửa khóa học khi trạng thái là "Đã tạo" hoặc "Đã thu hồi".', 16, 1);
        RETURN;
    END;

    -- Cập nhật khóa học
    UPDATE KhoaHoc
    SET 
        TenKhoaHoc = ISNULL(@TenKhoaHocMoi, TenKhoaHoc),
        MoTa = ISNULL(@MoTaMoi, MoTa),
        IdChuDe = ISNULL(@IdChuDeMoi, IdChuDe),
        CapDo = ISNULL(@CapDoMoi, CapDo),
        GiaKhoaHoc = ISNULL(@GiaKhoaHocMoi, GiaKhoaHoc)
    WHERE IdKhoaHoc = @IdKhoaHoc;

    -- Trả về ID của khóa học vừa cập nhật
    SELECT @IdKhoaHoc AS IdKhoaHoc;
END;
GO


--Xóa khóa học
DROP PROCEDURE IF EXISTS sp_XoaKhoaHoc;
GO
CREATE PROCEDURE sp_XoaKhoaHoc
    @IdGiangVien INT,
    @IdKhoaHoc INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra xem khóa học có tồn tại, thuộc quyền sở hữu của giảng viên 
    -- và có trạng thái "Đã tạo"
    IF NOT EXISTS (
        SELECT 1 
        FROM KhoaHoc 
        WHERE IdKhoaHoc = @IdKhoaHoc 
        AND IdGiangVien = @IdGiangVien
        AND TrangThai = N'Đã tạo'
    )
    BEGIN
        RAISERROR (N'Chỉ có thể xóa khóa học khi trạng thái là "Đã tạo".', 16, 1);
        RETURN;
    END;

    -- Xóa khóa học
    DELETE FROM KhoaHoc WHERE IdKhoaHoc = @IdKhoaHoc;

    -- Trả về ID của khóa học đã xóa
    SELECT @IdKhoaHoc AS IdKhoaHoc;
END;
GO
