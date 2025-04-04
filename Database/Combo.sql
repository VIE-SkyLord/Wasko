IF OBJECT_ID('dbo.Combo', 'U') IS NOT NULL
    DROP TABLE dbo.Combo;
GO

CREATE TABLE dbo.Combo
(
    IdCombo INT IDENTITY(1,1) PRIMARY KEY,
    IdGiangVien INT NOT NULL,            -- Tham chiếu sang GiangVien(IdTK)
    SoLuongKhoaHoc INT NOT NULL,
    MoTaCombo NVARCHAR(500) NULL,
    PhanTramKhuyenMai DECIMAL(5,2) NULL, -- % khuyến mãi (tùy nhu cầu)

    CONSTRAINT FK_Combo_GiangVien
        FOREIGN KEY (IdGiangVien) REFERENCES dbo.GiangVien(IdTK)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
GO

CREATE NONCLUSTERED INDEX IX_Combo_IdGiangVien
    ON dbo.Combo(IdGiangVien);
GO

IF OBJECT_ID('dbo.spCombo_Them', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spCombo_Them;
GO

CREATE PROCEDURE dbo.spCombo_Them
    @IdGiangVien INT,
    @SoLuongKhoaHoc INT,
    @MoTaCombo NVARCHAR(500) = NULL,
    @PhanTramKhuyenMai DECIMAL(5,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra Giảng viên có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM dbo.GiangVien WHERE IdTK = @IdGiangVien)
    BEGIN
        RAISERROR(N'Giảng viên không tồn tại!', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO dbo.Combo
        (
            IdGiangVien,
            SoLuongKhoaHoc,
            MoTaCombo,
            PhanTramKhuyenMai
        )
        VALUES
        (
            @IdGiangVien,
            @SoLuongKhoaHoc,
            @MoTaCombo,
            @PhanTramKhuyenMai
        );

        COMMIT TRANSACTION;
        SELECT N'Tạo combo thành công!' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        RAISERROR(N'Lỗi khi tạo combo!', 16, 1);
    END CATCH
END;
GO

IF OBJECT_ID('dbo.spCombo_Sua', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spCombo_Sua;
GO

CREATE PROCEDURE dbo.spCombo_Sua
    @IdCombo INT,
    @MoTaCombo NVARCHAR(500) = NULL,
    @PhanTramKhuyenMai DECIMAL(5,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Combo WHERE IdCombo = @IdCombo)
    BEGIN
        RAISERROR(N'Combo không tồn tại!', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE dbo.Combo
        SET MoTaCombo = @MoTaCombo,
            PhanTramKhuyenMai = @PhanTramKhuyenMai
        WHERE IdCombo = @IdCombo;

        COMMIT TRANSACTION;
        SELECT N'Sửa combo thành công!' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        RAISERROR(N'Lỗi khi sửa combo!', 16, 1);
    END CATCH
END;
GO

IF OBJECT_ID('dbo.spCombo_Xoa', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spCombo_Xoa;
GO

CREATE PROCEDURE dbo.spCombo_Xoa
    @IdCombo INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Combo WHERE IdCombo = @IdCombo)
    BEGIN
        RAISERROR(N'Combo không tồn tại!', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM dbo.Combo
        WHERE IdCombo = @IdCombo;

        COMMIT TRANSACTION;
        SELECT N'Xóa combo thành công!' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        RAISERROR(N'Lỗi khi xóa combo!', 16, 1);
    END CATCH
END;
GO