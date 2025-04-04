IF OBJECT_ID('dbo.HocVien_Combo', 'U') IS NOT NULL
    DROP TABLE dbo.HocVien_Combo;
GO

CREATE TABLE dbo.HocVien_Combo
(
    IdTK INT NOT NULL,
    IdCombo INT NOT NULL,
    TrangThai NVARCHAR(50) NOT NULL,  -- 'gio_hang' hoặc 'da_mua', v.v.

    CONSTRAINT PK_HocVien_Combo PRIMARY KEY (IdTK, IdCombo),

    CONSTRAINT FK_HocVien_Combo_HocVien FOREIGN KEY (IdTK)
        REFERENCES dbo.HocVien(IdTK)
        ON DELETE CASCADE,

    CONSTRAINT FK_HocVien_Combo_Combo FOREIGN KEY (IdCombo)
        REFERENCES dbo.Combo(IdCombo)
        ON DELETE NO ACTION
);
GO

IF OBJECT_ID('dbo.spHocVienCombo_ThemVaoGio', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spHocVienCombo_ThemVaoGio;
GO

CREATE PROCEDURE dbo.spHocVienCombo_ThemVaoGio
    @IdTK INT,
    @IdCombo INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1) Kiểm tra học viên, combo có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM dbo.HocVien WHERE IdTK = @IdTK)
    BEGIN
        RAISERROR(N'Học viên không tồn tại!', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.Combo WHERE IdCombo = @IdCombo)
    BEGIN
        RAISERROR(N'Combo không tồn tại!', 16, 1);
        RETURN;
    END

    -- 2) Kiểm tra đã có row HocVien_Combo chưa
    IF EXISTS (SELECT 1 FROM dbo.HocVien_Combo
               WHERE IdTK = @IdTK
                 AND IdCombo = @IdCombo)
    BEGIN
        -- Nếu đã mua, cấm thêm vào giỏ
        IF EXISTS (SELECT 1 FROM dbo.HocVien_Combo
                   WHERE IdTK = @IdTK
                     AND IdCombo = @IdCombo
                     AND TrangThai = N'da_mua')
        BEGIN
            RAISERROR(N'Combo này đã mua, không thể thêm vào giỏ!', 16, 1);
            RETURN;
        END

        -- Nếu đang là giỏ hàng thì không cần thêm
        SELECT N'Combo đã nằm trong giỏ hàng!' AS Message;
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 3) Chưa có row => Thêm mới
        INSERT INTO dbo.HocVien_Combo (IdTK, IdCombo, TrangThai)
        VALUES (@IdTK, @IdCombo, N'gio_hang');

        COMMIT TRANSACTION;
        SELECT N'Đã thêm combo vào giỏ hàng!' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        RAISERROR(N'Lỗi khi thêm combo vào giỏ!', 16, 1);
    END CATCH
END;
GO

IF OBJECT_ID('dbo.spHocVienCombo_Mua', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spHocVienCombo_Mua;
GO

IF OBJECT_ID('dbo.spHocVienCombo_Mua', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spHocVienCombo_Mua;
GO

CREATE PROCEDURE dbo.spHocVienCombo_Mua
    @IdHocVien INT,
    @IdCombo INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1) Kiểm tra học viên, combo
    IF NOT EXISTS (SELECT 1 FROM dbo.HocVien WHERE IdHocVien = @IdHocVien)
    BEGIN
        RAISERROR(N'Học viên không tồn tại!', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.Combo WHERE IdCombo = @IdCombo)
    BEGIN
        RAISERROR(N'Combo không tồn tại!', 16, 1);
        RETURN;
    END

    -- 2) Kiểm tra row HocVien_Combo (bảng trung gian giữa HocVien & Combo)
    IF NOT EXISTS (SELECT 1 FROM dbo.HocVien_Combo
                   WHERE IdTK = @IdHocVien
                     AND IdCombo = @IdCombo)
    BEGIN
        -- Nếu chưa có => Tùy logic, ta thêm cặp (IdHocVien, IdCombo) vào giỏ hay mua luôn
        BEGIN TRY
            BEGIN TRANSACTION;

            INSERT INTO dbo.HocVien_Combo (IdTK, IdCombo, TrangThai)
            VALUES (@IdHocVien, @IdCombo, N'da_mua');

            COMMIT TRANSACTION;
            SELECT N'Combo đã được mua (thêm mới)!' AS Message;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            RAISERROR(N'Lỗi khi mua combo (thêm mới)!', 16, 1);
            RETURN;
        END CATCH
    END
    ELSE
    BEGIN
        -- Nếu đã tồn tại => Kiểm tra trạng thái
        IF EXISTS (SELECT 1 FROM dbo.HocVien_Combo
                   WHERE IdTK = @IdHocVien
                     AND IdCombo = @IdCombo
                     AND TrangThai = N'da_mua')
        BEGIN
            SELECT N'Combo này đã được mua trước đó!' AS Message;
            RETURN;
        END

        -- Chuyển từ 'gio_hang' -> 'da_mua'
        BEGIN TRY
            BEGIN TRANSACTION;

            UPDATE dbo.HocVien_Combo
            SET TrangThai = N'da_mua'
            WHERE IdTK = @IdHocVien
              AND IdCombo = @IdCombo;

            COMMIT TRANSACTION;
            SELECT N'Mua combo thành công!' AS Message;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            RAISERROR(N'Lỗi khi mua combo!', 16, 1);
            RETURN;
        END CATCH
    END

    -- 3) Thêm các khóa học trong combo vào HocVien_KhoaHoc
    --    (sau khi combo đã được đánh dấu 'da_mua')
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Lấy danh sách khóa học thuộc combo
        INSERT INTO dbo.HocVien_KhoaHoc (IdHocVien, IdKhoaHoc)
        SELECT @IdHocVien, kc.IdKhoaHoc
        FROM dbo.KhoaHoc_Combo kc
        WHERE kc.IdCombo = @IdCombo
          -- Chỉ thêm nếu học viên chưa sở hữu khóa học này
          AND NOT EXISTS (
              SELECT 1
              FROM dbo.HocVien_KhoaHoc hvkh
              WHERE hvkh.IdHocVien = @IdHocVien
                AND hvkh.IdKhoaHoc = kc.IdKhoaHoc
          );

        COMMIT TRANSACTION;
        SELECT N'Đã thêm các khóa học trong combo vào sở hữu của học viên!' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        RAISERROR(N'Lỗi khi thêm khóa học từ combo vào sở hữu!', 16, 1);
    END CATCH
END;
GO

IF OBJECT_ID('dbo.spHocVienCombo_Xoa', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spHocVienCombo_Xoa;
GO

CREATE PROCEDURE dbo.spHocVienCombo_Xoa
    @IdTK INT,
    @IdCombo INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.HocVien_Combo
                   WHERE IdTK = @IdTK
                     AND IdCombo = @IdCombo)
    BEGIN
        RAISERROR(N'Không tìm thấy combo trong giỏ/mua!', 16, 1);
        RETURN;
    END

    -- Nếu đã mua, cấm xóa
    IF EXISTS (SELECT 1 FROM dbo.HocVien_Combo
               WHERE IdTK = @IdTK
                 AND IdCombo = @IdCombo
                 AND TrangThai = N'da_mua')
    BEGIN
        RAISERROR(N'Combo đã mua, không thể xóa!', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM dbo.HocVien_Combo
        WHERE IdTK = @IdTK
          AND IdCombo = @IdCombo;

        COMMIT TRANSACTION;
        SELECT N'Xóa combo khỏi giỏ hàng thành công!' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        RAISERROR(N'Lỗi khi xóa combo!', 16, 1);
    END CATCH
END;
GO
