-- Indexes for performance
CREATE INDEX IX_Courses_Status ON Courses(Status);
CREATE INDEX IX_Courses_CategoryId ON Courses(CategoryId);
CREATE INDEX IX_Courses_InstructorId ON Courses(InstructorId);
CREATE INDEX IX_Lessons_CourseId ON Lessons(CourseId);
CREATE INDEX IX_LearningMaterials_LessonId ON LearningMaterials(LessonId);
CREATE INDEX IX_CourseEnrollments_StudentId ON CourseEnrollments(StudentId);
CREATE INDEX IX_CourseEnrollments_CourseId ON CourseEnrollments(CourseId);
CREATE INDEX IX_CourseProgress_StudentId_CourseId ON CourseProgress(StudentId, CourseId);
CREATE INDEX IX_Payments_StudentId ON Payments(StudentId);
CREATE INDEX IX_Transactions_UserId ON Transactions(UserId);
CREATE INDEX IX_Reviews_CourseId ON Reviews(CourseId);