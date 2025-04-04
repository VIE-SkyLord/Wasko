-- Trigger to update course rating when new review is added
CREATE TRIGGER trg_UpdateCourseRating
ON Reviews
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Temporary table to hold affected course IDs
    DECLARE @AffectedCourses TABLE (CourseId INT);
    
    -- Insert course IDs from inserted rows
    INSERT INTO @AffectedCourses
    SELECT CourseId FROM inserted;
    
    -- Insert course IDs from deleted rows
    INSERT INTO @AffectedCourses
    SELECT CourseId FROM deleted;
    
    -- Update rating for each affected course
    UPDATE c
    SET c.Rating = ISNULL((SELECT AVG(CAST(r.Rating AS DECIMAL(3,2)))
                         FROM Reviews r
                         WHERE r.CourseId = c.CourseId), 0.0),
        c.UpdatedDate = GETDATE()
    FROM Courses c
    INNER JOIN @AffectedCourses ac ON c.CourseId = ac.CourseId;
END;

-- Trigger to update course progress when a lesson is completed
CREATE TRIGGER trg_UpdateCourseProgress
ON LessonCompletions
AFTER INSERT
AS
BEGIN
    DECLARE @StudentId INT, @LessonId INT, @CourseId INT;
    
    SELECT @StudentId = i.StudentId, @LessonId = i.LessonId
    FROM inserted i;
    
    SELECT @CourseId = l.CourseId
    FROM Lessons l
    WHERE l.LessonId = @LessonId;
    
    -- Calculate new completion percentage
    WITH LessonCounts AS (
        SELECT 
            COUNT(l.LessonId) AS TotalLessons,
            COUNT(lc.LessonId) AS CompletedLessons
        FROM Lessons l
        LEFT JOIN LessonCompletions lc ON l.LessonId = lc.LessonId AND lc.StudentId = @StudentId
        WHERE l.CourseId = @CourseId
    )
    UPDATE cp
    SET cp.CompletionPercentage = (SELECT (CAST(CompletedLessons AS DECIMAL(5,2)) / CAST(TotalLessons AS DECIMAL(5,2))) * 100 FROM LessonCounts),
        cp.LastAccessDate = GETDATE()
    FROM CourseProgress cp
    WHERE cp.StudentId = @StudentId AND cp.CourseId = @CourseId;
    
    -- Insert progress record if it doesn't exist
    IF @@ROWCOUNT = 0
    BEGIN
        WITH LessonCounts AS (
            SELECT 
                COUNT(l.LessonId) AS TotalLessons,
                COUNT(lc.LessonId) AS CompletedLessons
            FROM Lessons l
            LEFT JOIN LessonCompletions lc ON l.LessonId = lc.LessonId AND lc.StudentId = @StudentId
            WHERE l.CourseId = @CourseId
        )
        INSERT INTO CourseProgress (StudentId, CourseId, LastAccessDate, CompletionPercentage)
        SELECT 
            @StudentId, 
            @CourseId, 
            GETDATE(), 
            (SELECT (CAST(CompletedLessons AS DECIMAL(5,2)) / CAST(TotalLessons AS DECIMAL(5,2))) * 100 FROM LessonCounts);
    END
END;