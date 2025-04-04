-- Procedure to enroll a student in a course
CREATE PROCEDURE sp_EnrollStudentInCourse
    @StudentId INT,
    @CourseId INT,
    @PaymentId INT = NULL
AS
BEGIN
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Check if course exists and is published
        IF NOT EXISTS (SELECT 1 FROM Courses WHERE CourseId = @CourseId AND Status = 'PUBLISHED')
        BEGIN
            RAISERROR('Course does not exist or is not published', 16, 1);
            RETURN;
        END
        
        -- Check if student is already enrolled
        IF EXISTS (SELECT 1 FROM CourseEnrollments WHERE StudentId = @StudentId AND CourseId = @CourseId)
        BEGIN
            RAISERROR('Student is already enrolled in this course', 16, 1);
            RETURN;
        END
        
        -- Create enrollment record
        INSERT INTO CourseEnrollments (StudentId, CourseId, EnrollmentDate)
        VALUES (@StudentId, @CourseId, GETDATE());
        
        -- Initialize progress tracking
        INSERT INTO CourseProgress (StudentId, CourseId, LastAccessDate, CompletionPercentage)
        VALUES (@StudentId, @CourseId, GETDATE(), 0.0);
        
        -- Link to payment if provided
        IF @PaymentId IS NOT NULL
        BEGIN
            UPDATE Payments
            SET Status = 'COMPLETED'
            WHERE PaymentId = @PaymentId AND StudentId = @StudentId;
        END
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;

-- Procedure to process payment for a course
CREATE PROCEDURE sp_ProcessCoursePayment
    @StudentId INT,
    @CourseIds NVARCHAR(MAX), -- Comma-separated course IDs
    @PaymentMethod NVARCHAR(50),
    @TransactionId NVARCHAR(100) = NULL
AS
BEGIN
    DECLARE @TotalAmount DECIMAL(10,2) = 0;
    DECLARE @PaymentId INT;
    
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Calculate total amount
        SELECT @TotalAmount = SUM(Price)
        FROM Courses
        WHERE CourseId IN (SELECT value FROM STRING_SPLIT(@CourseIds, ','))
        AND Status = 'PUBLISHED';
        
        -- Create payment record
        INSERT INTO Payments (StudentId, Amount, PaymentDate, Status, TransactionId, PaymentMethod)
        VALUES (@StudentId, @TotalAmount, GETDATE(), 'COMPLETED', @TransactionId, @PaymentMethod);
        
        SET @PaymentId = SCOPE_IDENTITY();
        
        -- Create payment details for each course
        INSERT INTO PaymentDetails (PaymentId, CourseId, Amount)
        SELECT @PaymentId, CourseId, Price
        FROM Courses
        WHERE CourseId IN (SELECT value FROM STRING_SPLIT(@CourseIds, ','))
        AND Status = 'PUBLISHED';
        
        -- Process instructor profit
        DECLARE @CourseId INT;
        DECLARE @InstructorId INT;
        DECLARE @CoursePrice DECIMAL(10,2);
        DECLARE @ProfitRate DECIMAL(5,2);
        DECLARE @InstructorProfit DECIMAL(10,2);
        DECLARE @SystemFee DECIMAL(10,2);
        
        DECLARE CoursesCursor CURSOR FOR
        SELECT CourseId
        FROM Courses
        WHERE CourseId IN (SELECT value FROM STRING_SPLIT(@CourseIds, ','))
        AND Status = 'PUBLISHED';
        
        OPEN CoursesCursor;
        FETCH NEXT FROM CoursesCursor INTO @CourseId;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Get course details
            SELECT @InstructorId = InstructorId, @CoursePrice = Price
            FROM Courses
            WHERE CourseId = @CourseId;
            
            -- Get instructor profit rate
            SELECT TOP 1 @ProfitRate = ProfitRate
            FROM InstructorProfitRates
            WHERE InstructorId = @InstructorId
            ORDER BY EffectiveDate DESC;
            
            -- Calculate profits
            SET @InstructorProfit = @CoursePrice * (@ProfitRate / 100);
            SET @SystemFee = @CoursePrice - @InstructorProfit;
            
            -- Record instructor profit
            INSERT INTO Transactions (UserId, Amount, Type, Status, Date, Description)
            VALUES (@InstructorId, @InstructorProfit, 'COURSE_PURCHASE', 'COMPLETED', GETDATE(), 
                    'Profit from course ID: ' + CAST(@CourseId AS NVARCHAR(10)));
            
            -- Update instructor balance
            UPDATE Users
            SET Balance = Balance + @InstructorProfit
            WHERE UserId = @InstructorId;
            
            -- Enroll student in course
            EXEC sp_EnrollStudentInCourse @StudentId, @CourseId, @PaymentId;
            
            FETCH NEXT FROM CoursesCursor INTO @CourseId;
        END
        
        CLOSE CoursesCursor;
        DEALLOCATE CoursesCursor;
        
        -- Clear student's cart
        DELETE FROM CartItems
        WHERE CartId IN (SELECT CartId FROM Carts WHERE StudentId = @StudentId)
        AND CourseId IN (SELECT value FROM STRING_SPLIT(@CourseIds, ','));
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;

-- Procedure to issue a certificate
CREATE PROCEDURE sp_IssueCertificate
    @StudentId INT,
    @CourseId INT
AS
BEGIN
    DECLARE @CompletionPercentage DECIMAL(5,2);
    DECLARE @CertificateNumber NVARCHAR(100);
    
    -- Check if student is enrolled in the course
    IF NOT EXISTS (SELECT 1 FROM CourseEnrollments WHERE StudentId = @StudentId AND CourseId = @CourseId)
    BEGIN
        RAISERROR('Student is not enrolled in this course', 16, 1);
        RETURN;
    END
    
    -- Check if certificate already exists
    IF EXISTS (SELECT 1 FROM Certificates WHERE StudentId = @StudentId AND CourseId = @CourseId)
    BEGIN
        RAISERROR('Certificate has already been issued', 16, 1);
        RETURN;
    END
    
    -- Get completion percentage
    SELECT @CompletionPercentage = CompletionPercentage
    FROM CourseProgress
    WHERE StudentId = @StudentId AND CourseId = @CourseId;
    
    -- Check if course is completed
    IF @CompletionPercentage < 100
    BEGIN
        RAISERROR('Course is not fully completed yet', 16, 1);
        RETURN;
    END
    
    -- Generate certificate number
    SET @CertificateNumber = 'CERT-' + CAST(@CourseId AS NVARCHAR(10)) + '-' + 
                             CAST(@StudentId AS NVARCHAR(10)) + '-' + 
                             REPLACE(CONVERT(NVARCHAR(20), GETDATE(), 112), ' ', '');
    
    -- Issue certificate
    INSERT INTO Certificates (CourseId, StudentId, IssueDate, CertificateNumber)
    VALUES (@CourseId, @StudentId, GETDATE(), @CertificateNumber);
    
    -- Return certificate number
    SELECT @CertificateNumber AS CertificateNumber;
END;

-- Procedure to withdraw money (for instructors and administrators)
CREATE PROCEDURE sp_WithdrawMoney
    @UserId INT,
    @Amount DECIMAL(10,2)
AS
BEGIN
    DECLARE @CurrentBalance DECIMAL(10,2);
    DECLARE @MinimumWithdrawal DECIMAL(10,2) = 50000.00; -- 50,000 VND
    
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Get current balance
        SELECT @CurrentBalance = Balance
        FROM Users
        WHERE UserId = @UserId;
        
        -- Check if user exists
        IF @CurrentBalance IS NULL
        BEGIN
            RAISERROR('User does not exist', 16, 1);
            RETURN;
        END
        
        -- Check if amount is valid
        IF @Amount < @MinimumWithdrawal
        BEGIN
            RAISERROR('Minimum withdrawal amount is 50,000 VND', 16, 1);
            RETURN;
        END
        
        -- Check if user has sufficient balance
        IF @CurrentBalance < @Amount
        BEGIN
            RAISERROR('Insufficient balance', 16, 1);
            RETURN;
        END
        
        -- Create transaction record
        INSERT INTO Transactions (UserId, Amount, Type, Status, Date, Description)
        VALUES (@UserId, @Amount, 'PROFIT_WITHDRAWAL', 'COMPLETED', GETDATE(), 'Withdrawal to e-wallet');
        
        -- Update user balance
        UPDATE Users
        SET Balance = Balance - @Amount
        WHERE UserId = @UserId;
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;