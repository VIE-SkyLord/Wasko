CREATE TABLE DMChuDe
(
    IdChuDe INT IDENTITY(1,1) PRIMARY KEY,
    TenChuDe NVARCHAR(100) NOT NULL
);

INSERT INTO DMChuDe(TenChuDe)
VALUES(N'Khóa học khác'); -- Đây là dòng mặc định

-- Thêm chỉ mục nếu cần tìm kiếm nhanh
CREATE NONCLUSTERED INDEX IX_DMChuDe_TenChuDe ON DMChuDe(TenChuDe);
GO

-- Stored Procedure: Thêm Chủ đề
CREATE PROCEDURE sp_DMChuDe_Them
    @CallerId INT,
    @TenChuDe NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra quyền: chỉ quản lý cấp cao mới được thêm
    IF NOT EXISTS (
        SELECT 1 FROM TaiKhoan
        WHERE IdTK = @CallerId
          AND VaiTro = 'QuanLyCapCao'
    )
    BEGIN
        RAISERROR(N'Bạn không có quyền thêm chủ đề!', 16, 1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM DMChuDe WHERE TenChuDe = @TenChuDe)
    BEGIN
        RAISERROR(N'Chủ đề đã tồn tại!', 16, 1);
        RETURN;
    END

    INSERT INTO DMChuDe(TenChuDe)
    VALUES(@TenChuDe);

    SELECT N'Thêm chủ đề thành công!' AS Message;
END
GO

-- Stored Procedure: Sửa Chủ đề
CREATE PROCEDURE sp_DMChuDe_Sua
    @CallerId INT,
    @IdChuDe INT,
    @TenChuDe NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra quyền
    IF NOT EXISTS (
        SELECT 1 FROM TaiKhoan
        WHERE IdTK = @CallerId
          AND VaiTro = 'QuanLyCapCao'
    )
    BEGIN
        RAISERROR(N'Bạn không có quyền sửa chủ đề!', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM DMChuDe WHERE IdChuDe = @IdChuDe)
    BEGIN
        RAISERROR(N'Không tìm thấy chủ đề!', 16, 1);
        RETURN;
    END

    UPDATE DMChuDe
    SET TenChuDe = @TenChuDe
    WHERE IdChuDe = @IdChuDe;

    SELECT N'Sửa chủ đề thành công!' AS Message;
END
GO

-- Stored Procedure: Xóa Chủ đề
CREATE PROCEDURE sp_DMChuDe_Xoa
    @CallerId INT,
    @IdChuDe INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra quyền
    IF NOT EXISTS (
        SELECT 1 FROM TaiKhoan
        WHERE IdTK = @CallerId
          AND VaiTro = 'QuanLyCapCao'
    )
    BEGIN
        RAISERROR(N'Bạn không có quyền xóa chủ đề!', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM DMChuDe WHERE IdChuDe = @IdChuDe)
    BEGIN
        RAISERROR(N'Không tìm thấy chủ đề!', 16, 1);
        RETURN;
    END

    -- Nếu ON DELETE CASCADE, xóa chủ đề sẽ xóa luôn các khóa học liên quan.
    DELETE FROM DMChuDe
    WHERE IdChuDe = @IdChuDe;

    SELECT N'Xóa chủ đề thành công!' AS Message;
END
GO
