-- Course performance view
CREATE VIEW vw_CoursePerformance AS
SELECT 
    c.CourseId,
    c.Title,
    c.Price,
    c.Status,
    u.Username AS InstructorName,
    cat.Name AS CategoryName,
    COUNT(DISTINCT ce.StudentId) AS EnrollmentCount,
    ISNULL(AVG(r.Rating), 0) AS AverageRating,
    COUNT(DISTINCT r.ReviewId) AS ReviewCount,
    SUM(pd.Amount) AS TotalRevenue,
    c.CreatedDate,
    c.UpdatedDate
FROM Courses c
JOIN Users u ON c.InstructorId = u.UserId
JOIN Categories cat ON c.CategoryId = cat.CategoryId
LEFT JOIN CourseEnrollments ce ON c.CourseId = ce.CourseId
LEFT JOIN Reviews r ON c.CourseId = r.CourseId
LEFT JOIN PaymentDetails pd ON c.CourseId = pd.CourseId
GROUP BY 
    c.CourseId,
    c.Title,
    c.Price,
    c.Status,
    u.Username,
    cat.Name,
    c.CreatedDate,
    c.UpdatedDate;

-- Instructor earnings view
CREATE VIEW vw_InstructorEarnings AS
SELECT 
    u.UserId,
    u.Username,
    u.Email,
    ISNULL(SUM(CASE WHEN t.Type = 'COURSE_PURCHASE' THEN t.Amount ELSE 0 END), 0) AS TotalEarnings,
    ISNULL(SUM(CASE WHEN t.Type = 'PROFIT_WITHDRAWAL' THEN t.Amount ELSE 0 END), 0) AS TotalWithdrawn,
    u.Balance AS CurrentBalance,
    COUNT(DISTINCT c.CourseId) AS CourseCount,
    SUM(CASE WHEN c.Status = 'PUBLISHED' THEN 1 ELSE 0 END) AS PublishedCourseCount,
    AVG(c.Rating) AS AverageRating
FROM Users u
LEFT JOIN Transactions t ON u.UserId = t.UserId
LEFT JOIN Courses c ON u.UserId = c.InstructorId
WHERE u.Role = 'INSTRUCTOR'
GROUP BY 
    u.UserId,
    u.Username,
    u.Email,
    u.Balance;

-- Student progress view
CREATE VIEW vw_StudentProgress AS
SELECT 
    u.UserId,
    u.Username,
    c.CourseId,
    c.Title AS CourseTitle,
    ce.EnrollmentDate,
    cp.LastAccessDate,
    cp.CompletionPercentage,
    COUNT(DISTINCT lc.LessonId) AS CompletedLessons,
    (SELECT COUNT(*) FROM Lessons WHERE CourseId = c.CourseId) AS TotalLessons,
    COUNT(DISTINCT qa.QuizId) AS CompletedQuizzes,
    (SELECT COUNT(*) FROM Quizzes q JOIN Lessons l ON q.LessonId = l.LessonId WHERE l.CourseId = c.CourseId) AS TotalQuizzes,
    CASE WHEN cert.CertificateId IS NOT NULL THEN 'Yes' ELSE 'No' END AS CertificateIssued
FROM Users u
JOIN CourseEnrollments ce ON u.UserId = ce.StudentId
JOIN Courses c ON ce.CourseId = c.CourseId
LEFT JOIN CourseProgress cp ON u.UserId = cp.StudentId AND c.CourseId = cp.CourseId
LEFT JOIN LessonCompletions lc ON u.UserId = lc.StudentId 
    AND lc.LessonId IN (SELECT LessonId FROM Lessons WHERE CourseId = c.CourseId)
LEFT JOIN QuizAttempts qa ON u.UserId = qa.StudentId 
    AND qa.Passed = 1 
    AND qa.QuizId IN (SELECT q.QuizId FROM Quizzes q JOIN Lessons l ON q.LessonId = l.LessonId WHERE l.CourseId = c.CourseId)
LEFT JOIN Certificates cert ON u.UserId = cert.StudentId AND c.CourseId = cert.CourseId
WHERE u.Role = 'STUDENT'
GROUP BY 
    u.UserId,
    u.Username,
    c.CourseId,
    c.Title,
    ce.EnrollmentDate,
    cp.LastAccessDate,
    cp.CompletionPercentage,
    cert.CertificateId;

-- Monthly revenue view
CREATE VIEW vw_MonthlyRevenue AS
SELECT 
    YEAR(p.PaymentDate) AS Year,
    MONTH(p.PaymentDate) AS Month,
    SUM(p.Amount) AS TotalRevenue,
    COUNT(DISTINCT p.PaymentId) AS PaymentCount,
    COUNT(DISTINCT p.StudentId) AS StudentCount,
    COUNT(DISTINCT pd.CourseId) AS CourseCount
FROM Payments p
JOIN PaymentDetails pd ON p.PaymentId = pd.PaymentId
WHERE p.Status = 'COMPLETED'
GROUP BY 
    YEAR(p.PaymentDate),
    MONTH(p.PaymentDate);