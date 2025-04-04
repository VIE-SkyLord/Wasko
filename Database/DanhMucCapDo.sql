CREATE TABLE DMCapDo
(
    IdCapDo INT IDENTITY(1,1) PRIMARY KEY,
    TenCapDo NVARCHAR(100) NOT NULL
);

CREATE NONCLUSTERED INDEX IX_DMCapDo_TenCapDo ON DMCapDo(TenCapDo);
GO

-- Stored Procedure: Thêm cấp độ
CREATE PROCEDURE sp_DMCapDo_Them
    @CallerId INT,
    @TenCapDo NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra quyền: chỉ Quản lý cấp cao mới được thêm cấp độ
    IF NOT EXISTS (
        SELECT 1 FROM TaiKhoan
        WHERE IdTK = @CallerId AND VaiTro = 'QuanLyCapCao'
    )
    BEGIN
        RAISERROR(N'Bạn không có quyền thêm cấp độ!', 16, 1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM DMCapDo WHERE TenCapDo = @TenCapDo)
    BEGIN
        RAISERROR(N'Cấp độ đã tồn tại!', 16, 1);
        RETURN;
    END

    INSERT INTO DMCapDo(TenCapDo)
    VALUES(@TenCapDo);

    SELECT N'Thêm cấp độ thành công!' AS Message;
END
GO

-- Stored Procedure: Sửa cấp độ
CREATE PROCEDURE sp_DMCapDo_Sua
    @CallerId INT,
    @IdCapDo INT,
    @TenCapDo NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra quyền: chỉ Quản lý cấp cao mới được sửa cấp độ
    IF NOT EXISTS (
        SELECT 1 FROM TaiKhoan
        WHERE IdTK = @CallerId AND VaiTro = 'QuanLyCapCao'
    )
    BEGIN
        RAISERROR(N'Bạn không có quyền sửa cấp độ!', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM DMCapDo WHERE IdCapDo = @IdCapDo)
    BEGIN
        RAISERROR(N'Không tìm thấy cấp độ!', 16, 1);
        RETURN;
    END

    UPDATE DMCapDo
    SET TenCapDo = @TenCapDo
    WHERE IdCapDo = @IdCapDo;

    SELECT N'Sửa cấp độ thành công!' AS Message;
END
GO

-- Stored Procedure: Xóa cấp độ
CREATE PROCEDURE sp_DMCapDo_Xoa
    @CallerId INT,
    @IdCapDo INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra quyền: chỉ Quản lý cấp cao mới được xóa cấp độ
    IF NOT EXISTS (
        SELECT 1 FROM TaiKhoan
        WHERE IdTK = @CallerId AND VaiTro = 'QuanLyCapCao'
    )
    BEGIN
        RAISERROR(N'Bạn không có quyền xóa cấp độ!', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM DMCapDo WHERE IdCapDo = @IdCapDo)
    BEGIN
        RAISERROR(N'Không tìm thấy cấp độ!', 16, 1);
        RETURN;
    END

    DELETE FROM DMCapDo
    WHERE IdCapDo = @IdCapDo;

    SELECT N'Xóa cấp độ thành công!' AS Message;
END
GO
