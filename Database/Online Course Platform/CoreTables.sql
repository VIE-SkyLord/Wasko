-- User table (base table for all user types)
CREATE TABLE Users (
    UserId INT PRIMARY KEY IDENTITY(1,1),
    Username NVARCHAR(50) NOT NULL UNIQUE,
    Password NVARCHAR(255) NOT NULL,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    PhoneNumber NVARCHAR(20) NULL UNIQUE,
    Role NVARCHAR(20) NOT NULL CHECK (Role IN ('STUDENT', 'INSTRUCTOR', 'ADMINISTRATOR', 'COURSE_REVIEWER')),
    Balance DECIMAL(10,2) NOT NULL DEFAULT 0.0,
    CreatedDate DATETIME NOT NULL DEFAULT GETDATE()
);

-- Categories table
CREATE TABLE Categories (
    CategoryId INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500) NULL,
    ParentCategoryId INT NULL,
    FOREIGN KEY (ParentCategoryId) REFERENCES Categories(CategoryId)
);

-- Courses table
CREATE TABLE Courses (
    CourseId INT PRIMARY KEY IDENTITY(1,1),
    Title NVARCHAR(200) NOT NULL,
    Description NVARCHAR(2000) NULL,
    Price DECIMAL(10,2) NOT NULL DEFAULT 0.0,
    CategoryId INT NOT NULL,
    InstructorId INT NOT NULL,
    Rating DECIMAL(3,2) NULL DEFAULT 0.0,
    Status NVARCHAR(20) NOT NULL CHECK (Status IN ('DRAFT', 'PENDING_REVIEW', 'APPROVED', 'PUBLISHED', 'ARCHIVED')),
    CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedDate DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (CategoryId) REFERENCES Categories(CategoryId),
    FOREIGN KEY (InstructorId) REFERENCES Users(UserId)
);

-- Lessons table
CREATE TABLE Lessons (
    LessonId INT PRIMARY KEY IDENTITY(1,1),
    Title NVARCHAR(200) NOT NULL,
    Description NVARCHAR(1000) NULL,
    CourseId INT NOT NULL,
    Sequence INT NOT NULL,
    Duration INT NULL, -- In minutes
    Status NVARCHAR(20) NOT NULL CHECK (Status IN ('DRAFT', 'PUBLISHED', 'ARCHIVED')),
    FOREIGN KEY (CourseId) REFERENCES Courses(CourseId)
);

-- Learning Materials table
CREATE TABLE LearningMaterials (
    MaterialId INT PRIMARY KEY IDENTITY(1,1),
    Title NVARCHAR(200) NOT NULL,
    Description NVARCHAR(500) NULL,
    Type NVARCHAR(20) NOT NULL CHECK (Type IN ('VIDEO', 'DOCUMENT', 'QUIZ', 'ASSIGNMENT')),
    Content NVARCHAR(MAX) NULL,
    FileUrl NVARCHAR(500) NULL,
    LessonId INT NOT NULL,
    Sequence INT NOT NULL,
    FOREIGN KEY (LessonId) REFERENCES Lessons(LessonId)
);

-- Quizzes table
CREATE TABLE Quizzes (
    QuizId INT PRIMARY KEY IDENTITY(1,1),
    Title NVARCHAR(200) NOT NULL,
    Description NVARCHAR(500) NULL,
    LessonId INT NOT NULL,
    PassingScore INT NOT NULL DEFAULT 60,
    FOREIGN KEY (LessonId) REFERENCES Lessons(LessonId)
);

-- Questions table
CREATE TABLE Questions (
    QuestionId INT PRIMARY KEY IDENTITY(1,1),
    Content NVARCHAR(1000) NOT NULL,
    QuizId INT NOT NULL,
    FOREIGN KEY (QuizId) REFERENCES Quizzes(QuizId)
);

-- Options table
CREATE TABLE Options (
    OptionId INT PRIMARY KEY IDENTITY(1,1),
    QuestionId INT NOT NULL,
    Content NVARCHAR(500) NOT NULL,
    IsCorrect BIT NOT NULL DEFAULT 0,
    FOREIGN KEY (QuestionId) REFERENCES Questions(QuestionId)
);