IF OBJECT_ID('dbo.KhoaHoc_Combo', 'U') IS NOT NULL
    DROP TABLE dbo.KhoaHoc_Combo;
GO

CREATE TABLE dbo.KhoaHoc_Combo
(
    IdKhoaHoc INT NOT NULL,
    IdCombo INT NOT NULL,

    CONSTRAINT PK_KhoaHoc_Combo
        PRIMARY KEY (IdKhoaHoc, IdCombo),

    CONSTRAINT FK_KhoaHoc_Combo_KhoaHoc
        FOREIGN KEY (IdKhoaHoc)
        REFERENCES dbo.KhoaHoc(IdKhoaHoc)
        ON DELETE NO ACTION,   -- Hoặc NO ACTION, tùy nhu cầu

    CONSTRAINT FK_KhoaHoc_Combo_Combo
        FOREIGN KEY (IdCombo)
        REFERENCES dbo.Combo(IdCombo)
        ON DELETE CASCADE    -- Hoặc NO ACTION, tùy nhu cầu
);
GO

IF OBJECT_ID('dbo.spKhoaHocCombo_ThemKhoaHoc', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spKhoaHocCombo_ThemKhoaHoc;
GO

CREATE PROCEDURE dbo.spKhoaHocCombo_ThemKhoaHoc
    @IdKhoaHoc INT,
    @IdCombo INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1) Kiểm tra khóa học, combo có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM dbo.KhoaHoc WHERE IdKhoaHoc = @IdKhoaHoc)
    BEGIN
        RAISERROR(N'Khóa học không tồn tại!', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.Combo WHERE IdCombo = @IdCombo)
    BEGIN
        RAISERROR(N'Combo không tồn tại!', 16, 1);
        RETURN;
    END

    -- 2) Kiểm tra xem đã có cặp (IdKhoaHoc, IdCombo) chưa
    IF EXISTS (SELECT 1 FROM dbo.KhoaHoc_Combo
               WHERE IdKhoaHoc = @IdKhoaHoc
                 AND IdCombo = @IdCombo)
    BEGIN
        SELECT N'Khóa học này đã nằm trong combo!';
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 3) Thêm cặp (IdKhoaHoc, IdCombo)
        INSERT INTO dbo.KhoaHoc_Combo (IdKhoaHoc, IdCombo)
        VALUES (@IdKhoaHoc, @IdCombo);

        COMMIT TRANSACTION;
        SELECT N'Đã thêm khóa học vào combo thành công!' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        RAISERROR(N'Lỗi khi thêm khóa học vào combo!', 16, 1);
    END CATCH
END;
GO

IF OBJECT_ID('dbo.spKhoaHocCombo_XoaKhoaHoc', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spKhoaHocCombo_XoaKhoaHoc;
GO

CREATE PROCEDURE dbo.spKhoaHocCombo_XoaKhoaHoc
    @IdKhoaHoc INT,
    @IdCombo INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra xem cặp (IdKhoaHoc, IdCombo) có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM dbo.KhoaHoc_Combo
                   WHERE IdKhoaHoc = @IdKhoaHoc
                     AND IdCombo = @IdCombo)
    BEGIN
        RAISERROR(N'Không tìm thấy cặp (khóa học - combo)!', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM dbo.KhoaHoc_Combo
        WHERE IdKhoaHoc = @IdKhoaHoc
          AND IdCombo = @IdCombo;

        COMMIT TRANSACTION;
        SELECT N'Đã xóa khóa học khỏi combo thành công!' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        RAISERROR(N'Lỗi khi xóa khóa học khỏi combo!', 16, 1);
    END CATCH
END;
GO