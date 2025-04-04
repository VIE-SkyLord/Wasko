-- Course Enrollments table
CREATE TABLE CourseEnrollments (
    EnrollmentId INT PRIMARY KEY IDENTITY(1,1),
    StudentId INT NOT NULL,
    CourseId INT NOT NULL,
    EnrollmentDate DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (StudentId) REFERENCES Users(UserId),
    FOREIGN KEY (CourseId) REFERENCES Courses(CourseId),
    UNIQUE (StudentId, CourseId)
);

-- Course Progress table
CREATE TABLE CourseProgress (
    ProgressId INT PRIMARY KEY IDENTITY(1,1),
    StudentId INT NOT NULL,
    CourseId INT NOT NULL,
    LastAccessDate DATETIME NULL,
    CompletionPercentage DECIMAL(5,2) NOT NULL DEFAULT 0.0,
    FOREIGN KEY (StudentId) REFERENCES Users(UserId),
    FOREIGN KEY (CourseId) REFERENCES Courses(CourseId),
    UNIQUE (StudentId, CourseId)
);

-- Lesson Completion table
CREATE TABLE LessonCompletions (
    CompletionId INT PRIMARY KEY IDENTITY(1,1),
    StudentId INT NOT NULL,
    LessonId INT NOT NULL,
    CompletionDate DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (StudentId) REFERENCES Users(UserId),
    FOREIGN KEY (LessonId) REFERENCES Lessons(LessonId),
    UNIQUE (StudentId, LessonId)
);

-- Quiz Attempts table
CREATE TABLE QuizAttempts (
    AttemptId INT PRIMARY KEY IDENTITY(1,1),
    StudentId INT NOT NULL,
    QuizId INT NOT NULL,
    Score INT NOT NULL,
    Passed BIT NOT NULL DEFAULT 0,
    AttemptDate DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (StudentId) REFERENCES Users(UserId),
    FOREIGN KEY (QuizId) REFERENCES Quizzes(QuizId)
);

-- Quiz Answers table
CREATE TABLE QuizAnswers (
    AnswerId INT PRIMARY KEY IDENTITY(1,1),
    AttemptId INT NOT NULL,
    QuestionId INT NOT NULL,
    SelectedOptionId INT NOT NULL,
    IsCorrect BIT NOT NULL,
    FOREIGN KEY (AttemptId) REFERENCES QuizAttempts(AttemptId),
    FOREIGN KEY (QuestionId) REFERENCES Questions(QuestionId),
    FOREIGN KEY (SelectedOptionId) REFERENCES Options(OptionId)
);