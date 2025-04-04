CREATE PROCEDURE sp_DangKyNguoiDung
    @Email NVARCHAR(100),
    @SoDienThoai NVARCHAR(20),
    @MatKhau NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Kiểm tra xem Email hoặc Số điện thoại đã được đăng ký chưa
    IF EXISTS (SELECT 1 FROM NguoiDung
               WHERE Email = @Email OR SoDienThoai = @SoDienThoai)
    BEGIN
        RAISERROR('Email hoặc số điện thoại đã được đăng ký', 16, 1);
        RETURN;
    END

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Băm mật khẩu (SHA2_256)
        DECLARE @MatKhauHash VARBINARY(64) = HASHBYTES('SHA2_256', @MatKhau);

        -- Vai trò mặc định là Học viên (MaVaiTro = 1)
        DECLARE @MaVaiTro INT = 1;

        -- Insert người dùng mới, tên người dùng tạm thời để trống
        INSERT INTO NguoiDung (Email, SoDienThoai, MatKhau, TenNguoiDung, MaVaiTro)
        VALUES (@Email, @SoDienThoai, @MatKhauHash, NULL, @MaVaiTro);

        DECLARE @MaNguoiDung INT = SCOPE_IDENTITY();

        -- Tự động cập nhật tên người dùng theo cú pháp "Người dùng" + MaNguoiDung
        UPDATE NguoiDung
        SET TenNguoiDung = N'Người dùng' + CAST(@MaNguoiDung AS NVARCHAR(20))
        WHERE MaNguoiDung = @MaNguoiDung;

        COMMIT TRANSACTION;

        SELECT @MaNguoiDung AS MaNguoiDung;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        RAISERROR('Đăng ký không thành công', 16, 1);
    END CATCH;
END;
GO



CREATE PROCEDURE sp_DangNhap
    @Login NVARCHAR(100),  -- Email hoặc số điện thoại
    @MatKhau NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @MaNguoiDung INT, 
        @TenNguoiDung NVARCHAR(100), 
        @MaVaiTro INT;

    -- Xác thực người dùng: kiểm tra Email hoặc SoDienThoai và mật khẩu
    SELECT 
        @MaNguoiDung = MaNguoiDung, 
        @TenNguoiDung = TenNguoiDung,
        @MaVaiTro = MaVaiTro
    FROM NguoiDung 
    WHERE (@Login = Email OR @Login = SoDienThoai)
      AND MatKhau = @MatKhau;

    IF @MaNguoiDung IS NOT NULL
    BEGIN
        -- Tạo phiên đăng nhập (session)
        DECLARE @SessionID UNIQUEIDENTIFIER = NEWID();
        INSERT INTO PhienDangNhap (SessionID, MaNguoiDung, ThoiGianDangNhap)
        VALUES (@SessionID, @MaNguoiDung, GETDATE());

        -- Trả về thông tin người dùng cùng SessionID
        SELECT 
            @MaNguoiDung AS MaNguoiDung, 
            @TenNguoiDung AS TenNguoiDung, 
            VTN.TenVaiTro,
            @MaVaiTro AS MaVaiTro,
            @SessionID AS SessionID
        FROM VaiTroNguoiDung VTN
        WHERE VTN.MaVaiTro = @MaVaiTro;
    END
    ELSE
    BEGIN
        RAISERROR('Tên đăng nhập hoặc mật khẩu không đúng', 16, 1);
    END
END;
GO

CREATE PROCEDURE sp_DangXuat
    @SessionID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Kiểm tra xem phiên đăng nhập có tồn tại hay không
        IF NOT EXISTS (SELECT 1 FROM PhienDangNhap WHERE SessionID = @SessionID)
        BEGIN
            RAISERROR('Phiên đăng nhập không tồn tại', 16, 1);
            RETURN;
        END

        -- Cập nhật thời gian kết thúc phiên đăng nhập
        UPDATE PhienDangNhap
        SET ThoiGianKetThuc = GETDATE()
        WHERE SessionID = @SessionID;

        SELECT 1 AS ThanhCong;
    END TRY
    BEGIN CATCH
        RAISERROR('Lỗi đăng xuất', 16, 1);
    END CATCH
END;
GO

CREATE PROCEDURE sp_CapNhatThongTinTaiKhoan
    @MaNguoiDung INT,
    @TenNguoiDung NVARCHAR(100) = NULL,  -- Cập nhật nếu không NULL, ngược lại giữ nguyên
    @Email NVARCHAR(100) = NULL,         -- Cập nhật nếu không NULL
    @SoDienThoai NVARCHAR(20) = NULL,      -- Cập nhật nếu không NULL
    @MatKhau NVARCHAR(255) = NULL,         -- Nếu cung cấp, cập nhật mật khẩu mới (sẽ được băm)
    @ThanhCong BIT OUTPUT                -- Output: 1 nếu cập nhật thành công, 0 nếu không
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        UPDATE NguoiDung
        SET
            TenNguoiDung = COALESCE(@TenNguoiDung, TenNguoiDung),
            Email = COALESCE(@Email, Email),
            SoDienThoai = COALESCE(@SoDienThoai, SoDienThoai),
            MatKhau = CASE 
                        WHEN @MatKhau IS NOT NULL THEN HASHBYTES('SHA2_256', @MatKhau)
                        ELSE MatKhau 
                      END
        WHERE MaNguoiDung = @MaNguoiDung;

        -- Nếu có ít nhất 1 dòng bị cập nhật thì coi là thành công
        SET @ThanhCong = CASE WHEN @@ROWCOUNT > 0 THEN 1 ELSE 0 END;
    END TRY
    BEGIN CATCH
        SET @ThanhCong = 0;
        RAISERROR('Lỗi cập nhật thông tin tài khoản', 16, 1);
    END CATCH;
END;
GO
