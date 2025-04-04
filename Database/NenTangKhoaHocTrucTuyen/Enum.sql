USE NenTangKhoaHocTrucTuyen
GO

-- Tạo bảng kiểu liệt kê VaiTroNguoiDung
CREATE TABLE VaiTroNguoiDung (
    MaVaiTro INT PRIMARY KEY,
    TenVaiTro NVARCHAR(50) NOT NULL
)
GO

-- Tạo bảng kiểu liệt kê TrangThaiKhoaHoc
CREATE TABLE TrangThaiKhoaHoc (
    MaTrangThai INT PRIMARY KEY,
    TenTrangThai NVARCHAR(50) NOT NULL
)
GO

-- Tạo bảng kiểu liệt kê TrangThaiBaiHoc
CREATE TABLE TrangThaiBaiHoc (
    MaTrangThai INT PRIMARY KEY,
    TenTrangThai NVARCHAR(50) NOT NULL
)
GO

-- Tạo bảng kiểu liệt kê LoaiTaiLieu
CREATE TABLE LoaiTaiLieu (
    MaLoai INT PRIMARY KEY,
    TenLoai NVARCHAR(50) NOT NULL
)
GO

-- Tạo bảng kiểu liệt kê TrangThaiThanhToan
CREATE TABLE TrangThaiThanhToan (
    MaTrangThai INT PRIMARY KEY,
    TenTrangThai NVARCHAR(50) NOT NULL
)
GO

-- Tạo bảng kiểu liệt kê LoaiGiaoDich
CREATE TABLE LoaiGiaoDich (
    MaLoai INT PRIMARY KEY,
    TenLoai NVARCHAR(50) NOT NULL
)
GO

-- Tạo bảng kiểu liệt kê TrangThaiGiaoDich
CREATE TABLE TrangThaiGiaoDich (
    MaTrangThai INT PRIMARY KEY,
    TenTrangThai NVARCHAR(50) NOT NULL
)
GO

-- Tạo bảng kiểu liệt kê LoaiBaoCao
CREATE TABLE LoaiBaoCao (
    MaLoai INT PRIMARY KEY,
    TenLoai NVARCHAR(50) NOT NULL
)
GO

-- Tạo bảng kiểu liệt kê LoaiHoatDong
CREATE TABLE LoaiHoatDong (
    MaLoai INT PRIMARY KEY,
    TenLoai NVARCHAR(50) NOT NULL
)
GO

-- Tạo bảng kiểu liệt kê LoaiHoanThanhBaiHoc
CREATE TABLE LoaiHoanThanhBaiHoc (
    MaLoai INT PRIMARY KEY,
    TenLoai NVARCHAR(50) NOT NULL
)
GO

-- Chèn dữ liệu cho bảng VaiTroNguoiDung
INSERT INTO VaiTroNguoiDung (MaVaiTro, TenVaiTro) VALUES
(1, N'HỌC_VIÊN'),
(2, N'GIẢNG_VIÊN'),
(3, N'QUẢN_TRỊ_VIÊN'),
(4, N'NGƯỜI_ĐÁNH_GIÁ_KHÓA_HỌC')
GO

-- Chèn dữ liệu cho bảng TrangThaiKhoaHoc
INSERT INTO TrangThaiKhoaHoc (MaTrangThai, TenTrangThai) VALUES
(1, N'BẢN_NHÁP'),
(2, N'ĐANG_CHỜ_DUYỆT'),
(3, N'ĐÃ_DUYỆT'),
(4, N'ĐÃ_XUẤT_BẢN'),
(5, N'ĐÃ_LƯU_TRỮ')
GO

-- Chèn dữ liệu cho bảng TrangThaiBaiHoc
INSERT INTO TrangThaiBaiHoc (MaTrangThai, TenTrangThai) VALUES
(1, N'BẢN_NHÁP'),
(2, N'ĐÃ_XUẤT_BẢN'),
(3, N'ĐÃ_LƯU_TRỮ')
GO

-- Chèn dữ liệu cho bảng LoaiTaiLieu
INSERT INTO LoaiTaiLieu (MaLoai, TenLoai) VALUES
(1, N'VIDEO'),
(2, N'TÀI_LIỆU'),
(3, N'BÀI_KIỂM_TRA'),
(4, N'BÀI_TẬP')
GO

-- Chèn dữ liệu cho bảng TrangThaiThanhToan
INSERT INTO TrangThaiThanhToan (MaTrangThai, TenTrangThai) VALUES
(1, N'ĐANG_CHỜ'),
(2, N'ĐÃ_HOÀN_THÀNH'),
(3, N'THẤT_BẠI'),
(4, N'ĐÃ_HOÀN_TIỀN')
GO

-- Chèn dữ liệu cho bảng LoaiGiaoDich
INSERT INTO LoaiGiaoDich (MaLoai, TenLoai) VALUES
(1, N'MUA_KHÓA_HỌC'),
(2, N'RÚT_LỢI_NHUẬN'),
(3, N'PHÍ_HỆ_THỐNG')
GO

-- Chèn dữ liệu cho bảng TrangThaiGiaoDich
INSERT INTO TrangThaiGiaoDich (MaTrangThai, TenTrangThai) VALUES
(1, N'ĐANG_CHỜ'),
(2, N'ĐÃ_HOÀN_THÀNH'),
(3, N'THẤT_BẠI')
GO

-- Chèn dữ liệu cho bảng LoaiBaoCao
INSERT INTO LoaiBaoCao (MaLoai, TenLoai) VALUES
(1, N'BÁN_HÀNG'),
(2, N'ĐĂNG_KÝ'),
(3, N'HOẠT_ĐỘNG_NGƯỜI_DÙNG'),
(4, N'HIỆU_SUẤT_KHÓA_HỌC'),
(5, N'CHIA_SẺ_LỢI_NHUẬN')
GO

-- Chèn dữ liệu cho bảng LoaiHoatDong
INSERT INTO LoaiHoatDong (MaLoai, TenLoai) VALUES
(1, N'BẮT_ĐẦU_XEM'),
(2, N'TẠM_DỪNG_XEM'),
(3, N'TIẾP_TỤC_XEM'),
(4, N'KẾT_THÚC_XEM'),
(5, N'MỞ_TÀI_LIỆU'),
(6, N'ĐÓNG_TÀI_LIỆU')
GO

-- Chèn dữ liệu cho bảng LoaiHoanThanhBaiHoc
INSERT INTO LoaiHoanThanhBaiHoc (MaLoai, TenLoai) VALUES
(1, N'DỰA_TRÊN_BÀI_KIỂM_TRA'),
(2, N'DỰA_TRÊN_TÀI_LIỆU'),
(3, N'CẢ_HAI')
GO
