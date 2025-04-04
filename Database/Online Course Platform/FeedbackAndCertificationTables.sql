-- Reviews table
CREATE TABLE Reviews (
    ReviewId INT PRIMARY KEY IDENTITY(1,1),
    CourseId INT NOT NULL,
    StudentId INT NOT NULL,
    Rating INT NOT NULL CHECK (Rating BETWEEN 1 AND 5),
    Comment NVARCHAR(1000) NULL,
    ReviewDate DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (CourseId) REFERENCES Courses(CourseId),
    FOREIGN KEY (StudentId) REFERENCES Users(UserId),
    UNIQUE (CourseId, StudentId)
);

-- Certificates table
CREATE TABLE Certificates (
    CertificateId INT PRIMARY KEY IDENTITY(1,1),
    CourseId INT NOT NULL,
    StudentId INT NOT NULL,
    IssueDate DATETIME NOT NULL DEFAULT GETDATE(),
    CertificateNumber NVARCHAR(100) NOT NULL UNIQUE,
    FOREIGN KEY (CourseId) REFERENCES Courses(CourseId),
    FOREIGN KEY (StudentId) REFERENCES Users(UserId),
    UNIQUE (CourseId, StudentId)
);

-- Course Feedback (from reviewers to instructors)
CREATE TABLE CourseFeedback (
    FeedbackId INT PRIMARY KEY IDENTITY(1,1),
    CourseId INT NOT NULL,
    ReviewerId INT NOT NULL,
    Feedback NVARCHAR(2000) NOT NULL,
    FeedbackDate DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (CourseId) REFERENCES Courses(CourseId),
    FOREIGN KEY (ReviewerId) REFERENCES Users(UserId)
);

-- Reports table
CREATE TABLE Reports (
    ReportId INT PRIMARY KEY IDENTITY(1,1),
    Type NVARCHAR(50) NOT NULL CHECK (Type IN ('SALES', 'ENROLLMENT', 'USER_ACTIVITY', 'COURSE_PERFORMANCE', 'PROFIT_SHARING')),
    GeneratedDate DATETIME NOT NULL DEFAULT GETDATE(),
    Period NVARCHAR(20) NULL, -- 'MONTH', 'QUARTER', 'YEAR'
    StartDate DATETIME NULL,
    EndDate DATETIME NULL,
    ReportData NVARCHAR(MAX) NULL -- JSON format to store report data
);