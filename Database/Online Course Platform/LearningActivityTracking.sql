-- Add new column to Lessons table for completion type
ALTER TABLE Lessons
ADD CompletionType NVARCHAR(20) NOT NULL DEFAULT 'QUIZ_BASED' CHECK (CompletionType IN ('QUIZ_BASED', 'MATERIAL_BASED', 'BOTH')),
    RequiredMaterialPercentage DECIMAL(5,2) NOT NULL DEFAULT 80.0;

-- Add new columns to LearningMaterials table
ALTER TABLE LearningMaterials
ADD RequiredTimeSpent INT NOT NULL DEFAULT 0,
    IsRequired BIT NOT NULL DEFAULT 1;

-- Learning Material Progress table to track student interaction with materials
CREATE TABLE LearningMaterialProgress (
    ProgressId INT PRIMARY KEY IDENTITY(1,1),
    StudentId INT NOT NULL,
    MaterialId INT NOT NULL,
    Viewed BIT NOT NULL DEFAULT 0,
    ViewDuration INT NOT NULL DEFAULT 0, -- In seconds
    LastAccessDate DATETIME NOT NULL DEFAULT GETDATE(),
    CompletionPercentage DECIMAL(5,2) NOT NULL DEFAULT 0.0,
    FOREIGN KEY (StudentId) REFERENCES Users(UserId),
    FOREIGN KEY (MaterialId) REFERENCES LearningMaterials(MaterialId),
    UNIQUE (StudentId, MaterialId)
);

-- Create table for tracking detailed learning activities
CREATE TABLE LearningActivities (
    ActivityId INT PRIMARY KEY IDENTITY(1,1),
    StudentId INT NOT NULL,
    MaterialId INT NOT NULL,
    Timestamp DATETIME NOT NULL DEFAULT GETDATE(),
    ActivityType NVARCHAR(20) NOT NULL CHECK (ActivityType IN ('VIEW_START', 'VIEW_PAUSE', 'VIEW_RESUME', 'VIEW_END', 'DOCUMENT_OPEN', 'DOCUMENT_CLOSE')),
    Position INT NULL, -- For tracking position in videos or documents
    SessionId NVARCHAR(50) NULL, -- To group related activities
    FOREIGN KEY (StudentId) REFERENCES Users(UserId),
    FOREIGN KEY (MaterialId) REFERENCES LearningMaterials(MaterialId)
);

-- Indexes for performance optimization
CREATE INDEX IX_LearningMaterialProgress_StudentId ON LearningMaterialProgress(StudentId);
CREATE INDEX IX_LearningMaterialProgress_MaterialId ON LearningMaterialProgress(MaterialId);
CREATE INDEX IX_LearningMaterialProgress_StudentId_MaterialId ON LearningMaterialProgress(StudentId, MaterialId);
CREATE INDEX IX_LearningActivities_StudentId ON LearningActivities(StudentId);
CREATE INDEX IX_LearningActivities_MaterialId ON LearningActivities(MaterialId);
CREATE INDEX IX_LearningActivities_Timestamp ON LearningActivities(Timestamp);
CREATE INDEX IX_LearningActivities_ActivityType ON LearningActivities(ActivityType);
CREATE INDEX IX_LearningActivities_SessionId ON LearningActivities(SessionId);

-- Trigger to update material progress when activities are recorded
CREATE TRIGGER trg_UpdateMaterialProgress
ON LearningActivities
AFTER INSERT
AS
BEGIN
    DECLARE @StudentId INT, @MaterialId INT, @ActivityType NVARCHAR(20), @Position INT;
    
    SELECT 
        @StudentId = i.StudentId, 
        @MaterialId = i.MaterialId,
        @ActivityType = i.ActivityType,
        @Position = i.Position
    FROM inserted i;
    
    -- Get material details to calculate completion
    DECLARE @RequiredTimeSpent INT;
    SELECT @RequiredTimeSpent = RequiredTimeSpent FROM LearningMaterials WHERE MaterialId = @MaterialId;
    
    -- For VIEW_END activities, update the progress
    IF @ActivityType = 'VIEW_END'
    BEGIN
        -- Calculate view duration from previous VIEW_START
        DECLARE @StartTime DATETIME, @ViewDuration INT;
        
        SELECT TOP 1 @StartTime = Timestamp 
        FROM LearningActivities 
        WHERE StudentId = @StudentId 
        AND MaterialId = @MaterialId 
        AND ActivityType = 'VIEW_START'
        AND SessionId = (SELECT TOP 1 SessionId FROM inserted)
        ORDER BY Timestamp DESC;
        
        IF @StartTime IS NOT NULL
        BEGIN
            SET @ViewDuration = DATEDIFF(SECOND, @StartTime, GETDATE());
            
            -- Update existing progress or insert new record
            IF EXISTS (SELECT 1 FROM LearningMaterialProgress WHERE StudentId = @StudentId AND MaterialId = @MaterialId)
            BEGIN
                UPDATE LearningMaterialProgress
                SET 
                    Viewed = 1,
                    ViewDuration = ViewDuration + @ViewDuration,
                    LastAccessDate = GETDATE(),
                    CompletionPercentage = CASE 
                        WHEN @RequiredTimeSpent > 0 THEN 
                            CASE
                                WHEN (ViewDuration + @ViewDuration) >= @RequiredTimeSpent THEN 100.0
                                ELSE (CAST((ViewDuration + @ViewDuration) AS DECIMAL(10,2)) / @RequiredTimeSpent) * 100.0
                            END
                        ELSE 100.0
                    END
                WHERE StudentId = @StudentId AND MaterialId = @MaterialId;
            END
            ELSE
            BEGIN
                INSERT INTO LearningMaterialProgress (StudentId, MaterialId, Viewed, ViewDuration, LastAccessDate, CompletionPercentage)
                VALUES (
                    @StudentId, 
                    @MaterialId, 
                    1, 
                    @ViewDuration, 
                    GETDATE(),
                    CASE 
                        WHEN @RequiredTimeSpent > 0 THEN 
                            CASE
                                WHEN @ViewDuration >= @RequiredTimeSpent THEN 100.0
                                ELSE (CAST(@ViewDuration AS DECIMAL(10,2)) / @RequiredTimeSpent) * 100.0
                            END
                        ELSE 100.0
                    END
                );
            END
        END
    END
    
    -- For DOCUMENT_OPEN activities, mark as viewed
    IF @ActivityType = 'DOCUMENT_OPEN'
    BEGIN
        IF EXISTS (SELECT 1 FROM LearningMaterialProgress WHERE StudentId = @StudentId AND MaterialId = @MaterialId)
        BEGIN
            UPDATE LearningMaterialProgress
            SET 
                Viewed = 1,
                LastAccessDate = GETDATE()
            WHERE StudentId = @StudentId AND MaterialId = @MaterialId;
        END
        ELSE
        BEGIN
            INSERT INTO LearningMaterialProgress (StudentId, MaterialId, Viewed, ViewDuration, LastAccessDate, CompletionPercentage)
            VALUES (@StudentId, @MaterialId, 1, 0, GETDATE(), 0.0);
        END
    END
END;

-- Trigger to check and update lesson completion based on material progress
CREATE TRIGGER trg_CheckMaterialBasedLessonCompletion
ON LearningMaterialProgress
AFTER UPDATE
AS
BEGIN
    -- Get the lesson ID associated with the material that was updated
    DECLARE @MaterialId INT, @StudentId INT, @LessonId INT, @CompletionType NVARCHAR(20), @RequiredPercentage DECIMAL(5,2);
    
    SELECT @MaterialId = i.MaterialId, @StudentId = i.StudentId
    FROM inserted i;
    
    -- Get the lesson ID and completion settings
    SELECT 
        @LessonId = lm.LessonId,
        @CompletionType = l.CompletionType,
        @RequiredPercentage = l.RequiredMaterialPercentage
    FROM LearningMaterials lm
    JOIN Lessons l ON lm.LessonId = l.LessonId
    WHERE lm.MaterialId = @MaterialId;
    
    -- Only process for material-based or both completion types
    IF @CompletionType IN ('MATERIAL_BASED', 'BOTH')
    BEGIN
        -- Calculate overall material completion percentage for the lesson
        DECLARE @MaterialCompletion DECIMAL(5,2);
        
        WITH RequiredMaterials AS (
            SELECT 
                lm.MaterialId,
                CASE WHEN lmp.CompletionPercentage IS NULL THEN 0 ELSE lmp.CompletionPercentage END AS CompletionPercentage,
                lm.IsRequired
            FROM LearningMaterials lm
            LEFT JOIN LearningMaterialProgress lmp ON lm.MaterialId = lmp.MaterialId AND lmp.StudentId = @StudentId
            WHERE lm.LessonId = @LessonId
        )
        SELECT @MaterialCompletion = 
            CASE 
                WHEN COUNT(CASE WHEN IsRequired = 1 THEN 1 ELSE NULL END) = 0 THEN 100.0
                ELSE SUM(CASE WHEN IsRequired = 1 THEN CompletionPercentage ELSE 0 END) / COUNT(CASE WHEN IsRequired = 1 THEN 1 ELSE NULL END)
            END
        FROM RequiredMaterials;
        
        -- Check if material completion meets the requirement
        IF @MaterialCompletion >= @RequiredPercentage
        BEGIN
            -- Now check if quiz completion is also required (for BOTH type)
            IF @CompletionType = 'BOTH'
            BEGIN
                -- Check if there's a quiz attached to this lesson and if it's been completed
                DECLARE @QuizId INT, @QuizPassed BIT = 0;
                
                SELECT @QuizId = QuizId 
                FROM Quizzes 
                WHERE LessonId = @LessonId;
                
                IF @QuizId IS NOT NULL
                BEGIN
                    SELECT @QuizPassed = CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END
                    FROM QuizAttempts
                    WHERE StudentId = @StudentId AND QuizId = @QuizId AND Passed = 1;
                    
                    -- Only mark lesson as completed if both materials and quiz are completed
                    IF @QuizPassed = 1
                    BEGIN
                        -- Mark lesson as completed if not already
                        IF NOT EXISTS (SELECT 1 FROM LessonCompletions WHERE StudentId = @StudentId AND LessonId = @LessonId)
                        BEGIN
                            INSERT INTO LessonCompletions (StudentId, LessonId, CompletionDate)
                            VALUES (@StudentId, @LessonId, GETDATE());
                        END
                    END
                END
            END
            ELSE -- For MATERIAL_BASED only
            BEGIN
                -- Mark lesson as completed if not already
                IF NOT EXISTS (SELECT 1 FROM LessonCompletions WHERE StudentId = @StudentId AND LessonId = @LessonId)
                BEGIN
                    INSERT INTO LessonCompletions (StudentId, LessonId, CompletionDate)
                    VALUES (@StudentId, @LessonId, GETDATE());
                END
            END
        END
    END
END;
