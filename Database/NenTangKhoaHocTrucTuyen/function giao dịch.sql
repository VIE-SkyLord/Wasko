CREATE PROCEDURE sp_XuLyGiaoDich
    @MaGiaoDich INT,
    @ThanhCong BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE 
            @MaNguoiDung INT,
            @SoTien DECIMAL(18,2),
            @MaLoaiGiaoDich INT,
            @MaTrangThaiGiaoDich INT,
            @SoDuHienTai DECIMAL(18,2);

        -- 1) Lấy thông tin giao dịch
        SELECT TOP 1
            @MaNguoiDung = MaNguoiDung,
            @SoTien = SoTien,
            @MaLoaiGiaoDich = MaLoaiGiaoDich,
            @MaTrangThaiGiaoDich = MaTrangThaiGiaoDich
        FROM GiaoDich
        WHERE MaGiaoDich = @MaGiaoDich;

        IF @MaNguoiDung IS NULL
        BEGIN
            RAISERROR(N'Không tìm thấy giao dịch', 16, 1);
            ROLLBACK TRANSACTION;
            SET @ThanhCong = 0;
            RETURN;
        END

        -- Kiểm tra trạng thái phải là ĐANG_CHỜ (1)
        IF @MaTrangThaiGiaoDich <> 1
        BEGIN
            RAISERROR(N'Giao dịch không ở trạng thái chờ xử lý', 16, 1);
            ROLLBACK TRANSACTION;
            SET @ThanhCong = 0;
            RETURN;
        END

        -- 2) Lấy số dư hiện tại của người dùng
        SELECT @SoDuHienTai = SoDu
        FROM NguoiDung
        WHERE MaNguoiDung = @MaNguoiDung;

        IF @SoDuHienTai IS NULL
        BEGIN
            RAISERROR(N'Người dùng không tồn tại', 16, 1);
            ROLLBACK TRANSACTION;
            SET @ThanhCong = 0;
            RETURN;
        END

        -- 3) Phân nhánh xử lý theo loại giao dịch
        IF @MaLoaiGiaoDich = 1
        BEGIN
            -- MUA_KHOA_HỌC: Trừ tiền học viên
            IF @SoDuHienTai < @SoTien
            BEGIN
                UPDATE GiaoDich
                SET MaTrangThaiGiaoDich = 3  -- THẤT_BẠI
                WHERE MaGiaoDich = @MaGiaoDich;

                RAISERROR(N'Số dư không đủ để mua khóa học', 16, 1);
                ROLLBACK TRANSACTION;
                SET @ThanhCong = 0;
                RETURN;
            END

            UPDATE NguoiDung
            SET SoDu = SoDu - @SoTien
            WHERE MaNguoiDung = @MaNguoiDung;

            UPDATE GiaoDich
            SET MaTrangThaiGiaoDich = 2  -- ĐÃ_HOÀN_THÀNH
            WHERE MaGiaoDich = @MaGiaoDich;

            SET @ThanhCong = 1;
        END
        ELSE IF @MaLoaiGiaoDich = 2
        BEGIN
            -- RÚT_LỢI_NHUẬN: Số tiền tối thiểu là 50.000 VND
            IF @SoTien < 50000
            BEGIN
                UPDATE GiaoDich
                SET MaTrangThaiGiaoDich = 3  -- THẤT_BẠI
                WHERE MaGiaoDich = @MaGiaoDich;

                RAISERROR(N'Số tiền rút phải tối thiểu 50.000 VND', 16, 1);
                ROLLBACK TRANSACTION;
                SET @ThanhCong = 0;
                RETURN;
            END

            IF @SoDuHienTai < @SoTien
            BEGIN
                UPDATE GiaoDich
                SET MaTrangThaiGiaoDich = 3  -- THẤT_BẠI
                WHERE MaGiaoDich = @MaGiaoDich;

                RAISERROR(N'Số dư không đủ để rút lợi nhuận', 16, 1);
                ROLLBACK TRANSACTION;
                SET @ThanhCong = 0;
                RETURN;
            END

            UPDATE NguoiDung
            SET SoDu = SoDu - @SoTien
            WHERE MaNguoiDung = @MaNguoiDung;

            UPDATE GiaoDich
            SET MaTrangThaiGiaoDich = 2  -- ĐÃ_HOÀN_THÀNH
            WHERE MaGiaoDich = @MaGiaoDich;

            SET @ThanhCong = 1;
        END
        ELSE
        BEGIN
            UPDATE GiaoDich
            SET MaTrangThaiGiaoDich = 3  -- THẤT_BẠI
            WHERE MaGiaoDich = @MaGiaoDich;

            RAISERROR(N'Loại giao dịch không hợp lệ', 16, 1);
            SET @ThanhCong = 0;
            ROLLBACK TRANSACTION;
            RETURN;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ThanhCong = 0;

        DECLARE @ErrMsg NVARCHAR(4000), @ErrSev INT, @ErrState INT;
        SELECT @ErrMsg = ERROR_MESSAGE(), @ErrSev = ERROR_SEVERITY(), @ErrState = ERROR_STATE();
        RAISERROR(@ErrMsg, @ErrSev, @ErrState);
    END CATCH
END;
GO
