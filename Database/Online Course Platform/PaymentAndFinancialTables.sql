-- Cart table
CREATE TABLE Carts (
    CartId INT PRIMARY KEY IDENTITY(1,1),
    StudentId INT NOT NULL,
    CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (StudentId) REFERENCES Users(UserId),
    UNIQUE (StudentId)
);

-- Cart Items table
CREATE TABLE CartItems (
    CartItemId INT PRIMARY KEY IDENTITY(1,1),
    CartId INT NOT NULL,
    CourseId INT NOT NULL,
    AddedDate DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (CartId) REFERENCES Carts(CartId),
    FOREIGN KEY (CourseId) REFERENCES Courses(CourseId),
    UNIQUE (CartId, CourseId)
);

-- Payments table
CREATE TABLE Payments (
    PaymentId INT PRIMARY KEY IDENTITY(1,1),
    StudentId INT NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    PaymentDate DATETIME NOT NULL DEFAULT GETDATE(),
    Status NVARCHAR(20) NOT NULL CHECK (Status IN ('PENDING', 'COMPLETED', 'FAILED', 'REFUNDED')),
    TransactionId NVARCHAR(100) NULL,
    PaymentMethod NVARCHAR(50) NULL,
    FOREIGN KEY (StudentId) REFERENCES Users(UserId)
);

-- Payment Details table
CREATE TABLE PaymentDetails (
    PaymentDetailId INT PRIMARY KEY IDENTITY(1,1),
    PaymentId INT NOT NULL,
    CourseId INT NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (PaymentId) REFERENCES Payments(PaymentId),
    FOREIGN KEY (CourseId) REFERENCES Courses(CourseId)
);

-- Instructor Profit Rates table
CREATE TABLE InstructorProfitRates (
    RateId INT PRIMARY KEY IDENTITY(1,1),
    InstructorId INT NOT NULL,
    ProfitRate DECIMAL(5,2) NOT NULL DEFAULT 70.0, -- Default 70% to instructor
    EffectiveDate DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (InstructorId) REFERENCES Users(UserId)
);

-- Transactions table
CREATE TABLE Transactions (
    TransactionId INT PRIMARY KEY IDENTITY(1,1),
    UserId INT NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    Type NVARCHAR(20) NOT NULL CHECK (Type IN ('COURSE_PURCHASE', 'PROFIT_WITHDRAWAL', 'SYSTEM_FEE')),
    Status NVARCHAR(20) NOT NULL CHECK (Status IN ('PENDING', 'COMPLETED', 'FAILED')),
    Date DATETIME NOT NULL DEFAULT GETDATE(),
    Description NVARCHAR(500) NULL,
    FOREIGN KEY (UserId) REFERENCES Users(UserId)
);