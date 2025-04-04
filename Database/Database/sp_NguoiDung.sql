USE Wasko;
GO
--TRUY CẬP HỆ THỐNG
--Kiểm tra mật khẩu
DROP FUNCTION IF EXISTS fn_KiemTraMatKhau;
GO
CREATE FUNCTION fn_KiemTraMatKhau
(
    @MatKhau NVARCHAR(100)
)
RETURNS BIT
AS
BEGIN
    DECLARE @KetQua BIT = 1;

    -- Kiểm tra độ dài (tối thiểu 8 ký tự)
    IF LEN(@MatKhau) < 8 SET @KetQua = 0;

    RETURN @KetQua;
END;
GO

--Đăng ký
DROP PROCEDURE IF EXISTS sp_DangKy;
GO
CREATE PROCEDURE sp_DangKy
    @Email NVARCHAR(100) = NULL,
    @SoDienThoai NVARCHAR(20) = NULL,
    @MatKhau NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

	-- Kiểm tra độ phức tạp mật khẩu
    IF dbo.fn_KiemTraMatKhau(@MatKhau) = 0
    BEGIN
        RAISERROR(N'Mật khẩu phải có ít nhất 8 ký tự, bao gồm chữ hoa, chữ thường, số và ký tự đặc biệt.', 16, 1);
        RETURN;
    END

    -- Kiểm tra bắt buộc nhập ít nhất Email hoặc Số điện thoại
    IF (@Email IS NULL AND @SoDienThoai IS NULL)
    BEGIN
        RAISERROR(N'Phải nhập Email hoặc Số điện thoại để đăng ký.', 16, 1);
        RETURN;
    END

    -- Kiểm tra trùng Email nếu có
    IF (@Email IS NOT NULL AND EXISTS(SELECT 1 FROM NguoiDung WHERE Email = @Email))
    BEGIN
        RAISERROR(N'Email đã được sử dụng.', 16, 1);
        RETURN;
    END

    -- Kiểm tra trùng Số điện thoại nếu có
    IF (@SoDienThoai IS NOT NULL AND EXISTS(SELECT 1 FROM NguoiDung WHERE SoDienThoai = @SoDienThoai))
    BEGIN
        RAISERROR(N'Số điện thoại đã được sử dụng.', 16, 1);
        RETURN;
    END

    DECLARE @NewId INT;
    
    -- Tạo salt ngẫu nhiên 16 bytes
    DECLARE @Salt VARBINARY(16) = CRYPT_GEN_RANDOM(16);
    -- Băm mật khẩu với salt sử dụng thuật toán SHA2_512
    DECLARE @HashedPassword VARBINARY(64) = HASHBYTES('SHA2_512', @Salt + CAST(@MatKhau AS VARBINARY(MAX)));

    -- Chèn dữ liệu người dùng mới vào bảng NguoiDung với mật khẩu đã được băm và salt
    INSERT INTO NguoiDung (TenNguoiDung, VaiTro, SoDienThoai, Email, MatKhau, Salt, LyDoKhoa)
    VALUES (N'Người dùng', N'Học viên', @SoDienThoai, @Email, @HashedPassword, @Salt, NULL);

    -- Lấy giá trị Identity vừa tạo
    SET @NewId = SCOPE_IDENTITY();

    -- Cập nhật lại tên người dùng với giá trị "Người dùng" + IdNguoiDung
    UPDATE NguoiDung
    SET TenNguoiDung = N'Người dùng' + CAST(@NewId AS NVARCHAR(10))
    WHERE IdNguoiDung = @NewId;

    SELECT N'Đăng ký thành công!' AS Message;
END;
GO
--INSERT NguoiDung VALUES(N'Nguyễn Trung Kiên',N'Quản trị viên',N'0961380804',N'anhthien5487@gmail.com',N'123456',N'Đã đăng ký',NULL)
--SELECT * FROM NguoiDung WHERE VaiTro = N'Quản trị viên'
--INSERT NguoiDung VALUES(N'Nguyễn Đức Huy',N'Giảng viên',NULL,N'nguyenhuy20032003@gmail.com',N'123456',N'Đã đăng ký',NULL)
--INSERT NguoiDung VALUES(N'Hoàng Hồng Đức',N'Kiểm duyệt viên',NULL,N'hoanghongduc609@gmail.com',N'123456',N'Đã đăng ký',NULL)
--SELECT * FROM NguoiDung WHERE VaiTro = N'Kiểm duyệt viên'
EXEC sp_DangKy @Email = N'anhthien5487@gmail.com', @SoDienThoai = N'0961380804', @MatKhau = N'Aa123456';
EXEC sp_DangKy @Email = N'nguyenhuy20032003@gmail.com', @SoDienThoai = NULL, @MatKhau = 'Aa123456';
EXEC sp_DangKy @Email = N'hoanghongduc0609@gmail.com', @SoDienThoai = NULL, @MatKhau = 'Aa123456';
EXEC sp_DangKy @Email = NULL, @SoDienThoai = N'0987654321', @MatKhau = 'Aa123456';
SELECT * FROM NguoiDung

--Đăng nhập
DROP PROCEDURE IF EXISTS sp_DangNhap;
GO
CREATE PROCEDURE sp_DangNhap
    @Email NVARCHAR(100) = NULL,
    @SoDienThoai NVARCHAR(20) = NULL,
    @MatKhau NVARCHAR(100),
    @IdThietBi NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdNguoiDung INT, 
            @SaltHienTai VARBINARY(16), 
            @MatKhauDaLuu VARBINARY(64),
            @VaiTro NVARCHAR(50),
            @IdPhienDangNhap UNIQUEIDENTIFIER = NEWID();

    -- Lấy thông tin người dùng dựa trên Email hoặc Số điện thoại
    SELECT TOP 1
        @IdNguoiDung = IdNguoiDung,
        @SaltHienTai = Salt,
        @MatKhauDaLuu = MatKhau,
        @VaiTro = VaiTro
    FROM NguoiDung
    WHERE (Email = @Email OR SoDienThoai = @SoDienThoai)
      AND TrangThai IN (N'Đã đăng ký', N'Đang hoạt động');

    IF @IdNguoiDung IS NULL
    BEGIN
        RAISERROR(N'Thông tin đăng nhập không đúng.', 16, 1);
        RETURN;
    END

    -- Kiểm tra mật khẩu nhập vào bằng cách băm với salt của người dùng
    IF @MatKhauDaLuu <> HASHBYTES('SHA2_512', @SaltHienTai + CONVERT(VARBINARY(MAX), @MatKhau))
    BEGIN
        RAISERROR(N'Mật khẩu không đúng.', 16, 1);
        RETURN;
    END
	--Đổi trạng thái
	UPDATE NguoiDung SET TrangThai = N'Đang hoạt động' WHERE IdNguoiDung = @IdNguoiDung;
    -- Tạo phiên đăng nhập mới
    INSERT INTO PhienDangNhap (IdPhienDangNhap, IdNguoiDung, IdThietBi, ThoiDiemDangNhap, ThoiDiemQuaHan)
    VALUES (@IdPhienDangNhap, @IdNguoiDung, @IdThietBi, GETDATE(), DATEADD(HOUR, 1, GETDATE()));

    -- Trả về thông tin đăng nhập thành công, vai trò và SessionID
    SELECT N'Đăng nhập thành công!' AS Message, @VaiTro AS VaiTro, @IdPhienDangNhap AS SessionID;
END;
GO
EXEC sp_DangNhap @Email = NULL, @SoDienThoai = '0961380804', @MatKhau = 'Aa123456',@IdThietBi=N'Redmi Note 10';
EXEC sp_DangNhap 
    @Email = 'anhthien5487@gmail.com', 
    @SoDienThoai = NULL, 
    @MatKhau = 'Aa123456', 
    @IdThietBi = 'Device123';

-- Trigger quản lý phiên đăng nhập
DROP TRIGGER IF EXISTS TR_XoaPhienHetHan;
GO
CREATE TRIGGER TR_XoaPhienHetHan
ON PhienDangNhap
AFTER INSERT
AS
BEGIN
    DELETE FROM PhienDangNhap 
    WHERE ThoiDiemQuaHan < GETDATE();
END

--Đăng xuất
DROP PROCEDURE IF EXISTS sp_DangXuat;
GO
DROP PROCEDURE IF EXISTS sp_DangXuat;
GO
CREATE PROCEDURE sp_DangXuat
    @IdPhienDangNhap UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdNguoiDung INT;

    -- Lấy IdNguoiDung từ phiên đăng nhập
    SELECT @IdNguoiDung = IdNguoiDung
    FROM PhienDangNhap
    WHERE IdPhienDangNhap = @IdPhienDangNhap;

    IF @IdNguoiDung IS NULL
    BEGIN
        RAISERROR(N'Phiên đăng nhập không tồn tại.', 16, 1);
        RETURN;
    END

    -- Xóa phiên đăng nhập khỏi bảng PhienDangNhap
    DELETE FROM PhienDangNhap
    WHERE IdPhienDangNhap = @IdPhienDangNhap;

    -- Cập nhật trạng thái người dùng về 'Đã đăng ký'
    UPDATE NguoiDung
    SET TrangThai = N'Đã đăng ký'
    WHERE IdNguoiDung = @IdNguoiDung;

    SELECT N'Đăng xuất thành công!' AS Message;
END;
GO
--SELECT*FROM PhienDangNhap
EXEC sp_DangXuat @IdPhienDangNhap=N'6D8E1BA1-FE26-41A2-951C-3BF6DF2016A7';

--Cập nhật thông tin người dùng
DROP PROCEDURE IF EXISTS sp_CapNhatThongTinNguoiDung;
GO
CREATE PROCEDURE sp_CapNhatThongTinNguoiDung
    @IdNguoiDung INT,
    @TenNguoiDung NVARCHAR(100) = NULL,
    @Email NVARCHAR(100) = NULL,
    @SoDienThoai NVARCHAR(20) = NULL,
    @MatKhau NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra xem có ít nhất 1 trường thông tin được cập nhật hay không
    IF @TenNguoiDung IS NULL 
       AND @Email IS NULL 
       AND @SoDienThoai IS NULL 
       AND @MatKhau IS NULL
    BEGIN
        RAISERROR(N'Phải cập nhật ít nhất 1 trường thông tin.', 16, 1);
        RETURN;
    END

    -- Kiểm tra người dùng tồn tại và có trạng thái "Đang hoạt động"
    IF NOT EXISTS (
        SELECT 1 FROM NguoiDung 
        WHERE IdNguoiDung = @IdNguoiDung 
          AND TrangThai = N'Đang hoạt động'
    )
    BEGIN
        RAISERROR(N'Người dùng không tồn tại hoặc không ở trạng thái "Đang hoạt động".', 16, 1);
        RETURN;
    END

    -- Nếu có cập nhật mật khẩu, tạo salt mới và băm mật khẩu
    DECLARE @NewSalt VARBINARY(16) = NULL,
            @HashedPassword VARBINARY(64) = NULL;

    IF @MatKhau IS NOT NULL
    BEGIN
        SET @NewSalt = CRYPT_GEN_RANDOM(16);
        SET @HashedPassword = HASHBYTES('SHA2_512', @NewSalt + CONVERT(VARBINARY(MAX), @MatKhau));
    END

    -- Cập nhật thông tin, chỉ thay đổi các trường có tham số được truyền vào
    UPDATE NguoiDung
    SET 
        TenNguoiDung = COALESCE(@TenNguoiDung, TenNguoiDung),
        Email = COALESCE(@Email, Email),
        SoDienThoai = COALESCE(@SoDienThoai, SoDienThoai),
        Salt = CASE WHEN @MatKhau IS NOT NULL THEN @NewSalt ELSE Salt END,
        MatKhau = CASE WHEN @MatKhau IS NOT NULL THEN @HashedPassword ELSE MatKhau END
    WHERE IdNguoiDung = @IdNguoiDung
      AND TrangThai = N'Đang hoạt động';

    IF @@ROWCOUNT = 0
    BEGIN
        RAISERROR(N'Cập nhật không thành công.', 16, 1);
    END
    ELSE
    BEGIN
        SELECT N'Cập nhật thông tin thành công!' AS Message;
    END
END;
GO
--SELECT * FROM NguoiDung
EXEC sp_CapNhatThongTinNguoiDung @IdNguoiDung=1, @TenNguoiDung=N'Nguyễn Trung Kiên', @MatKhau=N'Aa654321';
EXEC sp_CapNhatThongTinNguoiDung @IdNguoiDung=2, @TenNguoiDung=N'Nguyễn Đức Huy', @MatKhau=N'Aa654321';
EXEC sp_CapNhatThongTinNguoiDung @IdNguoiDung=3, @TenNguoiDung=N'Hoàng Hồng Đức', @MatKhau=N'Aa654321';
EXEC sp_CapNhatThongTinNguoiDung @IdNguoiDung=4, @TenNguoiDung=N'Nguyễn Văn An', @MatKhau=N'Aa654321';
UPDATE NguoiDung SET VaiTro=N'Quản trị viên',TrangThai=N'Đang hoạt động' WHERE IdNguoiDung=1
UPDATE NguoiDung SET VaiTro=N'Giảng viên',TrangThai=N'Đang hoạt động' WHERE IdNguoiDung=2
UPDATE NguoiDung SET VaiTro=N'Kiểm duyệt viên',TrangThai=N'Đang hoạt động' WHERE IdNguoiDung=3

--PHÂN QUYỀN NGƯỜI DÙNG
DROP PROCEDURE IF EXISTS sp_PhanQuyen;
GO
CREATE PROCEDURE sp_PhanQuyen
	@IdNguoiDungHienTai INT,
    @IdNguoiDungCanPhanQuyen INT,
    @VaiTroMoi NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra admin
    IF NOT EXISTS (
        SELECT 1 
        FROM NguoiDung 
        WHERE IdNguoiDung = @IdNguoiDungHienTai 
        AND VaiTro = N'Quản trị viên'
    )
    BEGIN
        RAISERROR(N'Chỉ Quản trị viên mới được phép phân quyền', 16, 1);
        RETURN;
    END

    -- tìm vai trò người dùng cần phân quyền
    DECLARE @VaiTroHienTai NVARCHAR(50);
    SELECT @VaiTroHienTai = VaiTro
    FROM NguoiDung
    WHERE IdNguoiDung = @IdNguoiDungCanPhanQuyen;

    -- kiểm tra điều kiện phân quyền
    IF NOT (
        (@VaiTroHienTai = N'Học viên' AND @VaiTroMoi IN (N'Giảng viên', N'Kiểm duyệt viên')) OR
        (@VaiTroHienTai = N'Kiểm duyệt viên' AND @VaiTroMoi = N'Học viên') OR
        (@VaiTroHienTai = @VaiTroMoi)
    )
    BEGIN
        RAISERROR(N'Chuyển vai trò không được phép', 16, 1);
        RETURN;
    END

    -- Kiểm tra người dùng tồn tại
    IF NOT EXISTS (
        SELECT 1 
        FROM NguoiDung 
        WHERE IdNguoiDung = @IdNguoiDungCanPhanQuyen
    )
    BEGIN
        RAISERROR(N'Người dùng không tồn tại', 16, 1);
        RETURN;
    END

    -- Thực hiện chuyển vai trò
    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE NguoiDung
        SET VaiTro = @VaiTroMoi
        WHERE IdNguoiDung = @IdNguoiDungCanPhanQuyen;

        COMMIT TRANSACTION;
        PRINT N'Phân quyền thành công';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END
GO
--SELECT * FROM NguoiDung
EXEC sp_PhanQuyen @IdNguoiDungHienTai = 1, @IdNguoiDungCanPhanQuyen = 4, @VaiTroMoi = N'Học viên';

--KHÓA TÀI KHOẢN
DROP PROCEDURE IF EXISTS sp_KhoaTaiKhoan;
GO
CREATE PROCEDURE sp_KhoaTaiKhoan
    @IdNguoiDungThucHien INT,
	@IdNguoiDungCanThayDoi INT,
    @LyDo NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- vai trò người thực hiện
    DECLARE @VaiTroNguoiThucHien NVARCHAR(50);
    SELECT @VaiTroNguoiThucHien = VaiTro 
    FROM NguoiDung 
    WHERE IdNguoiDung = @IdNguoiDungThucHien;

    -- kiểm tra người thực hiện có phải là Quản trị viên không
    IF @VaiTroNguoiThucHien != N'Quản trị viên'
    BEGIN
        RAISERROR(N'Chỉ quản trị viên mới được phép thay đổi trạng thái tài khoản.', 16, 1);
        RETURN;
    END

    -- Tránh tự khóa chính mình
    IF @IdNguoiDungCanThayDoi = @IdNguoiDungThucHien
    BEGIN
        RAISERROR(N'Không được phép thay đổi trạng thái tài khoản của chính mình.', 16, 1);
        RETURN;
    END

    -- kiểm tra mục tiêu có tồn tại hay không
    IF NOT EXISTS (SELECT 1 FROM NguoiDung WHERE IdNguoiDung = @IdNguoiDungCanThayDoi)
    BEGIN
        RAISERROR(N'Người dùng không tồn tại.', 16, 1);
        RETURN;
    END

    -- trạng thái mục tiêu hiện tại
    DECLARE @TrangThaiHienTai NVARCHAR(50);
    SELECT @TrangThaiHienTai = TrangThai 
    FROM NguoiDung 
    WHERE IdNguoiDung = @IdNguoiDungCanThayDoi;

    -- khóa/gỡ khóa
    DECLARE @TrangThaiMoi NVARCHAR(50);
    
    IF @TrangThaiHienTai IN (N'Đã đăng ký', N'Đang hoạt động')
    BEGIN
        SET @TrangThaiMoi = N'Đã bị khóa';
    END
    ELSE IF @TrangThaiHienTai = N'Đã bị khóa'
    BEGIN
        SET @TrangThaiMoi = N'Đã đăng ký';
    END
    ELSE
    BEGIN
        RAISERROR(N'Trạng thái tài khoản không hợp lệ.', 16, 1);
        RETURN;
    END

    UPDATE NguoiDung
    SET 
        TrangThai = @TrangThaiMoi,
        LyDoKhoa = CASE 
            WHEN @TrangThaiMoi = N'Đã bị khóa' THEN @LyDo 
            ELSE NULL 
        END
    WHERE 
        IdNguoiDung = @IdNguoiDungCanThayDoi;

    IF @TrangThaiMoi = N'Đã bị khóa'
    BEGIN
        PRINT N'Tài khoản đã được khóa thành công.';
    END
    ELSE
    BEGIN
        PRINT N'Tài khoản đã được gỡ khóa và đưa về trạng thái đăng ký.';
    END
END
GO
--SELECT*FROM NguoiDung
EXEC sp_KhoaTaiKhoan @IdNguoiDungThucHien = 1, @IdNguoiDungCanThayDoi = 4, @LyDo = N'Vi phạm quy định sử dụng'