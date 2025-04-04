/*
    Kiểm tra và xóa bảng nếu tồn tại (dùng khi cần reset lại cấu trúc).
    Lưu ý: Sử dụng đúng thứ tự để tránh lỗi khóa ngoại.
*/
IF OBJECT_ID('dbo.PhuongAn', 'U') IS NOT NULL
    DROP TABLE dbo.PhuongAn;
GO

IF OBJECT_ID('dbo.CauHoiTracNghiem', 'U') IS NOT NULL
    DROP TABLE dbo.CauHoiTracNghiem;
GO

IF OBJECT_ID('dbo.Quiz', 'U') IS NOT NULL
    DROP TABLE dbo.Quiz;
GO

CREATE TABLE dbo.Quiz
(
    IdQuiz INT IDENTITY(1,1) PRIMARY KEY,
    IdBaiHoc INT NOT NULL,                -- Thay vì IdKhoaHoc
    PassingPercent DECIMAL(5,2) NOT NULL,  -- % qua quiz

    CONSTRAINT FK_Quiz_BaiHoc
        FOREIGN KEY (IdBaiHoc)
        REFERENCES dbo.BaiHoc(IdBaiHoc)
        ON DELETE CASCADE
);
GO

CREATE NONCLUSTERED INDEX IX_Quiz_IdBaiHoc
    ON dbo.Quiz(IdBaiHoc);
GO

-- Bảng Câu hỏi trắc nghiệm
CREATE TABLE dbo.CauHoiTracNghiem (
    cau_hoi_id INT IDENTITY(1,1) PRIMARY KEY,
    quiz_id INT NOT NULL,
    noi_dung NVARCHAR(500) NOT NULL,     -- nội dung câu hỏi
    dap_an_dung INT NOT NULL,            -- đáp án đúng (có thể là ID phương án hoặc thứ tự)
    diem_cau_hoi DECIMAL(5,2) NOT NULL,   -- điểm cho câu hỏi
    CONSTRAINT FK_Quiz_CauHoi
        FOREIGN KEY (quiz_id)
        REFERENCES dbo.Quiz(IdQuiz)
        ON DELETE CASCADE
);
GO

-- Bảng Phương án
CREATE TABLE dbo.PhuongAn (
    phuong_an_id INT IDENTITY(1,1) PRIMARY KEY,
    cau_hoi_id INT NOT NULL,
    noi_dung NVARCHAR(500) NOT NULL,  -- nội dung phương án
    CONSTRAINT FK_CauHoi_PhuongAn
        FOREIGN KEY (cau_hoi_id)
        REFERENCES dbo.CauHoiTracNghiem(cau_hoi_id)
        ON DELETE CASCADE
);
GO

IF OBJECT_ID('dbo.spAddQuiz', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spAddQuiz;
GO

CREATE PROCEDURE dbo.spAddQuiz
    @baiHocId INT,
    @passingPercent DECIMAL(5,2)
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra xem bài học có tồn tại không (nếu cần)
    IF NOT EXISTS (SELECT 1 FROM dbo.BaiHoc WHERE IdBaiHoc = @baiHocId)
    BEGIN
        RAISERROR(N'Bài học không tồn tại!', 16, 1);
        RETURN;
    END

    INSERT INTO dbo.Quiz (IdBaiHoc, PassingPercent)
    VALUES (@baiHocId, @passingPercent);
END;
GO

IF OBJECT_ID('dbo.spUpdateQuiz', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spUpdateQuiz;
GO

CREATE PROCEDURE dbo.spUpdateQuiz
    @quizId INT,
    @passingPercent DECIMAL(5,2)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Quiz WHERE IdQuiz = @quizId)
    BEGIN
        RAISERROR(N'Quiz không tồn tại!', 16, 1);
        RETURN;
    END

    UPDATE dbo.Quiz
    SET PassingPercent = @passingPercent
    WHERE IdQuiz = @quizId;
END;
GO

IF OBJECT_ID('dbo.spDeleteQuiz', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spDeleteQuiz;
GO

CREATE PROCEDURE dbo.spDeleteQuiz
    @quizId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Quiz WHERE IdQuiz = @quizId)
    BEGIN
        RAISERROR(N'Quiz không tồn tại!', 16, 1);
        RETURN;
    END

    DELETE FROM dbo.Quiz
    WHERE IdQuiz = @quizId;
END;
GO

IF OBJECT_ID('dbo.spAddCauHoiTracNghiem', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spAddCauHoiTracNghiem;
GO

CREATE PROCEDURE dbo.spAddCauHoiTracNghiem
    @quizId INT,
    @noiDung NVARCHAR(500),
    @dapAnDung INT,
    @diemCauHoi DECIMAL(5,2)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.CauHoiTracNghiem (quiz_id, noi_dung, dap_an_dung, diem_cau_hoi)
    VALUES (@quizId, @noiDung, @dapAnDung, @diemCauHoi);
END;
GO

IF OBJECT_ID('dbo.spUpdateCauHoiTracNghiem', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spUpdateCauHoiTracNghiem;
GO

CREATE PROCEDURE dbo.spUpdateCauHoiTracNghiem
    @cauHoiId INT,
    @noiDung NVARCHAR(500),
    @dapAnDung INT,
    @diemCauHoi DECIMAL(5,2)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.CauHoiTracNghiem
    SET
        noi_dung     = @noiDung,
        dap_an_dung  = @dapAnDung,
        diem_cau_hoi = @diemCauHoi
    WHERE cau_hoi_id = @cauHoiId;
END;
GO

IF OBJECT_ID('dbo.spDeleteCauHoiTracNghiem', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spDeleteCauHoiTracNghiem;
GO

CREATE PROCEDURE dbo.spDeleteCauHoiTracNghiem
    @cauHoiId INT
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM dbo.CauHoiTracNghiem
    WHERE cau_hoi_id = @cauHoiId;
END;
GO

IF OBJECT_ID('dbo.spAddPhuongAn', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spAddPhuongAn;
GO

CREATE PROCEDURE dbo.spAddPhuongAn
    @cauHoiId INT,
    @noiDung NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.PhuongAn (cau_hoi_id, noi_dung)
    VALUES (@cauHoiId, @noiDung);
END;
GO

IF OBJECT_ID('dbo.spUpdatePhuongAn', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spUpdatePhuongAn;
GO

CREATE PROCEDURE dbo.spUpdatePhuongAn
    @phuongAnId INT,
    @noiDung NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.PhuongAn
    SET noi_dung = @noiDung
    WHERE phuong_an_id = @phuongAnId;
END;
GO

IF OBJECT_ID('dbo.spDeletePhuongAn', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spDeletePhuongAn;
GO

CREATE PROCEDURE dbo.spDeletePhuongAn
    @phuongAnId INT
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM dbo.PhuongAn
    WHERE phuong_an_id = @phuongAnId;
END;
GO
