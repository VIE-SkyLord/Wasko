-- Tạo bảng KetQuaQuiz
IF OBJECT_ID('dbo.KetQuaQuiz', 'U') IS NOT NULL
    DROP TABLE dbo.KetQuaQuiz;
GO

CREATE TABLE dbo.KetQuaQuiz
(
    IdKetQua INT IDENTITY(1,1) PRIMARY KEY,
    IdHocVien INT NOT NULL,
    IdQuiz INT NOT NULL,

    LanLam INT NOT NULL,             -- Lần làm thứ mấy
    Diem DECIMAL(5,2) NOT NULL,       -- Điểm đạt được
    IsPass BIT NOT NULL,              -- 1: pass, 0: fail
    NgayThi DATETIME NOT NULL DEFAULT(GETDATE()),

    CONSTRAINT FK_KetQuaQuiz_HocVien
        FOREIGN KEY (IdHocVien)
        REFERENCES dbo.HocVien(IdTK)
        ON DELETE CASCADE,

    CONSTRAINT FK_KetQuaQuiz_Quiz
        FOREIGN KEY (IdQuiz)
        REFERENCES dbo.Quiz(IdQuiz)
        ON DELETE NO ACTION
);
GO

CREATE NONCLUSTERED INDEX IX_KetQuaQuiz_IdHocVien
    ON dbo.KetQuaQuiz(IdHocVien);
GO

CREATE NONCLUSTERED INDEX IX_KetQuaQuiz_IdQuiz
    ON dbo.KetQuaQuiz(IdQuiz);
GO

-- Stored Procedure: Thêm kết quả quiz (chỉ cho phép thêm nếu chưa có kết quả pass)
IF OBJECT_ID('dbo.spAddKetQuaQuiz', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spAddKetQuaQuiz;
GO

CREATE PROCEDURE dbo.spAddKetQuaQuiz
    @IdHocVien INT,
    @IdQuiz INT,
    @Diem DECIMAL(5,2),
    @IsPass BIT
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra xem học viên đã pass quiz này chưa
    IF EXISTS (
        SELECT 1 
        FROM dbo.KetQuaQuiz
        WHERE IdHocVien = @IdHocVien 
          AND IdQuiz = @IdQuiz 
          AND IsPass = 1
    )
    BEGIN
        RAISERROR(N'Học viên đã pass quiz này, không được thi lại!', 16, 1);
        RETURN;
    END

    -- Kiểm tra xem học viên và quiz có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM dbo.HocVien WHERE IdTK = @IdHocVien)
    BEGIN
        RAISERROR(N'Học viên không tồn tại!', 16, 1);
        RETURN;
    END
    IF NOT EXISTS (SELECT 1 FROM dbo.Quiz WHERE IdQuiz = @IdQuiz)
    BEGIN
        RAISERROR(N'Quiz không tồn tại!', 16, 1);
        RETURN;
    END

    -- Tính lần làm tiếp theo
    DECLARE @MaxLanLam INT;
    SELECT @MaxLanLam = ISNULL(MAX(LanLam), 0)
    FROM dbo.KetQuaQuiz
    WHERE IdHocVien = @IdHocVien
      AND IdQuiz = @IdQuiz;

    DECLARE @NextLanLam INT = @MaxLanLam + 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO dbo.KetQuaQuiz (IdHocVien, IdQuiz, LanLam, Diem, IsPass)
        VALUES (@IdHocVien, @IdQuiz, @NextLanLam, @Diem, @IsPass);

        COMMIT TRANSACTION;
        SELECT N'Thêm kết quả quiz (lần làm ' + CAST(@NextLanLam AS NVARCHAR(10)) + N') thành công!' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        RAISERROR(N'Lỗi khi thêm kết quả quiz!', 16, 1);
    END CATCH
END;
GO