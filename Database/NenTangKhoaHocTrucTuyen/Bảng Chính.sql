USE NenTangKhoaHocTrucTuyen
GO

-- Tạo bảng NguoiDung
CREATE TABLE NguoiDung (
    MaNguoiDung INT IDENTITY(1,1) PRIMARY KEY,
    TenNguoiDung NVARCHAR(100) NOT NULL,
    MatKhau NVARCHAR(255) NOT NULL,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    SoDienThoai NVARCHAR(20),
    MaVaiTro INT NOT NULL,
    SoDu DECIMAL(18,2) DEFAULT 0,
    CONSTRAINT FK_NguoiDung_VaiTroNguoiDung FOREIGN KEY (MaVaiTro) REFERENCES VaiTroNguoiDung(MaVaiTro)
)
GO

-- Tạo bảng DanhMuc
CREATE TABLE DanhMuc (
    MaDanhMuc INT IDENTITY(1,1) PRIMARY KEY,
    TenDanhMuc NVARCHAR(100) NOT NULL,
    MoTa NVARCHAR(500),
    MaDanhMucCha INT,
    CONSTRAINT FK_DanhMuc_DanhMucCha FOREIGN KEY (MaDanhMucCha) REFERENCES DanhMuc(MaDanhMuc)
)
GO

-- Tạo bảng KhoaHoc
CREATE TABLE KhoaHoc (
    MaKhoaHoc INT IDENTITY(1,1) PRIMARY KEY,
    TieuDe NVARCHAR(200) NOT NULL,
    MoTa NVARCHAR(MAX),
    Gia DECIMAL(18,2) NOT NULL,
    MaDanhMuc INT NOT NULL,
    MaGiangVien INT NOT NULL,
    XepHang DECIMAL(3,2) DEFAULT 0,
    MaTrangThai INT NOT NULL,
    NgayTao DATETIME NOT NULL DEFAULT GETDATE(),
    NgayCapNhat DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_KhoaHoc_DanhMuc FOREIGN KEY (MaDanhMuc) REFERENCES DanhMuc(MaDanhMuc),
    CONSTRAINT FK_KhoaHoc_NguoiDung FOREIGN KEY (MaGiangVien) REFERENCES NguoiDung(MaNguoiDung),
    CONSTRAINT FK_KhoaHoc_TrangThaiKhoaHoc FOREIGN KEY (MaTrangThai) REFERENCES TrangThaiKhoaHoc(MaTrangThai)
)
GO

-- Tạo bảng BaiHoc
CREATE TABLE BaiHoc (
    MaBaiHoc INT IDENTITY(1,1) PRIMARY KEY,
    TieuDe NVARCHAR(200) NOT NULL,
    MoTa NVARCHAR(MAX),
    MaKhoaHoc INT NOT NULL,
    ThuTu INT NOT NULL,
    ThoiLuong INT DEFAULT 0, -- Thời lượng tính bằng phút
    MaTrangThai INT NOT NULL,
    MaLoaiHoanThanh INT NOT NULL,
    PhanTramTaiLieuYeuCau DECIMAL(5,2) DEFAULT 80.00, -- Mặc định 80%
    CONSTRAINT FK_BaiHoc_KhoaHoc FOREIGN KEY (MaKhoaHoc) REFERENCES KhoaHoc(MaKhoaHoc),
    CONSTRAINT FK_BaiHoc_TrangThaiBaiHoc FOREIGN KEY (MaTrangThai) REFERENCES TrangThaiBaiHoc(MaTrangThai),
    CONSTRAINT FK_BaiHoc_LoaiHoanThanhBaiHoc FOREIGN KEY (MaLoaiHoanThanh) REFERENCES LoaiHoanThanhBaiHoc(MaLoai)
)
GO

-- Tạo bảng TaiLieuHocTap
CREATE TABLE TaiLieuHocTap (
    MaTaiLieu INT IDENTITY(1,1) PRIMARY KEY,
    TieuDe NVARCHAR(200) NOT NULL,
    MoTa NVARCHAR(MAX),
    MaLoaiTaiLieu INT NOT NULL,
    NoiDung NVARCHAR(MAX),
    URLTep NVARCHAR(255),
    MaBaiHoc INT NOT NULL,
    ThuTu INT NOT NULL,
    ThoiGianYeuCau INT DEFAULT 0, -- Thời gian yêu cầu tính bằng phút
    BatBuoc BIT DEFAULT 1, -- 1: Bắt buộc, 0: Không bắt buộc
    CONSTRAINT FK_TaiLieuHocTap_LoaiTaiLieu FOREIGN KEY (MaLoaiTaiLieu) REFERENCES LoaiTaiLieu(MaLoai),
    CONSTRAINT FK_TaiLieuHocTap_BaiHoc FOREIGN KEY (MaBaiHoc) REFERENCES BaiHoc(MaBaiHoc)
)
GO

-- Tạo bảng BaiKiemTra
CREATE TABLE BaiKiemTra (
    MaBaiKiemTra INT IDENTITY(1,1) PRIMARY KEY,
    TieuDe NVARCHAR(200) NOT NULL,
    MoTa NVARCHAR(MAX),
    MaBaiHoc INT NOT NULL,
    DiemDat INT DEFAULT 70, -- Điểm đạt mặc định là 70/100
    CONSTRAINT FK_BaiKiemTra_BaiHoc FOREIGN KEY (MaBaiHoc) REFERENCES BaiHoc(MaBaiHoc),
    CONSTRAINT UQ_BaiKiemTra_MaBaiHoc UNIQUE (MaBaiHoc) -- Mỗi bài học chỉ có 1 bài kiểm tra
)
GO

-- Tạo bảng CauHoi
CREATE TABLE CauHoi (
    MaCauHoi INT IDENTITY(1,1) PRIMARY KEY,
    NoiDung NVARCHAR(MAX) NOT NULL,
    MaBaiKiemTra INT NOT NULL,
    ChiSoLuaChonDung INT NOT NULL,
    CONSTRAINT FK_CauHoi_BaiKiemTra FOREIGN KEY (MaBaiKiemTra) REFERENCES BaiKiemTra(MaBaiKiemTra)
)
GO

-- Tạo bảng LuaChon
CREATE TABLE LuaChon (
    MaLuaChon INT IDENTITY(1,1) PRIMARY KEY,
    MaCauHoi INT NOT NULL,
    NoiDung NVARCHAR(MAX) NOT NULL,
    ThuTu INT NOT NULL,
    CONSTRAINT FK_LuaChon_CauHoi FOREIGN KEY (MaCauHoi) REFERENCES CauHoi(MaCauHoi)
)
GO

-- Tạo bảng đăng ký khóa học
CREATE TABLE DangKyKhoaHoc (
    MaDangKy INT IDENTITY(1,1) PRIMARY KEY,
    MaHocVien INT NOT NULL,
    MaKhoaHoc INT NOT NULL,
    NgayDangKy DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_DangKyKhoaHoc_NguoiDung FOREIGN KEY (MaHocVien) REFERENCES NguoiDung(MaNguoiDung),
    CONSTRAINT FK_DangKyKhoaHoc_KhoaHoc FOREIGN KEY (MaKhoaHoc) REFERENCES KhoaHoc(MaKhoaHoc),
    CONSTRAINT UQ_DangKyKhoaHoc UNIQUE (MaHocVien, MaKhoaHoc) -- Một học viên chỉ đăng ký một khóa học một lần
)
GO

-- Tạo bảng GiangVien
CREATE TABLE GiangVien (
    MaGiangVien INT PRIMARY KEY,
    TyLeLoiNhuan DECIMAL(5,2) DEFAULT 70.00, -- Tỷ lệ lợi nhuận mặc định 70%
    CONSTRAINT FK_GiangVien_NguoiDung FOREIGN KEY (MaGiangVien) REFERENCES NguoiDung(MaNguoiDung)
)
GO

-- Tạo bảng TienDoTaiLieuHocTap
CREATE TABLE TienDoTaiLieuHocTap (
    MaTienDoTaiLieu INT IDENTITY(1,1) PRIMARY KEY,
    MaHocVien INT NOT NULL,
    MaTaiLieu INT NOT NULL,
    DaXem BIT DEFAULT 0,
    ThoiLuongXem INT DEFAULT 0, -- Thời lượng xem tính bằng giây
    NgayTruyCapCuoiCung DATETIME,
    PhanTramHoanThanh DECIMAL(5,2) DEFAULT 0.00,
    CONSTRAINT FK_TienDoTaiLieuHocTap_NguoiDung FOREIGN KEY (MaHocVien) REFERENCES NguoiDung(MaNguoiDung),
    CONSTRAINT FK_TienDoTaiLieuHocTap_TaiLieuHocTap FOREIGN KEY (MaTaiLieu) REFERENCES TaiLieuHocTap(MaTaiLieu),
    CONSTRAINT UQ_TienDoTaiLieuHocTap UNIQUE (MaHocVien, MaTaiLieu)
)
GO

-- Tạo bảng HoatDongHocTap
CREATE TABLE HoatDongHocTap (
    MaHoatDong INT IDENTITY(1,1) PRIMARY KEY,
    MaHocVien INT NOT NULL,
    MaTaiLieu INT NOT NULL,
    ThoiGian DATETIME NOT NULL DEFAULT GETDATE(),
    MaLoaiHoatDong INT NOT NULL,
    ViTri INT DEFAULT 0, -- Vị trí trong tài liệu (giây nếu là video, trang nếu là tài liệu)
    CONSTRAINT FK_HoatDongHocTap_NguoiDung FOREIGN KEY (MaHocVien) REFERENCES NguoiDung(MaNguoiDung),
    CONSTRAINT FK_HoatDongHocTap_TaiLieuHocTap FOREIGN KEY (MaTaiLieu) REFERENCES TaiLieuHocTap(MaTaiLieu),
    CONSTRAINT FK_HoatDongHocTap_LoaiHoatDong FOREIGN KEY (MaLoaiHoatDong) REFERENCES LoaiHoatDong(MaLoai)
)
GO

-- Tạo bảng KetQuaBaiKiemTra
CREATE TABLE KetQuaBaiKiemTra (
    MaKetQua INT IDENTITY(1,1) PRIMARY KEY,
    MaHocVien INT NOT NULL,
    MaBaiKiemTra INT NOT NULL,
    DiemSo INT NOT NULL,
    DaDat BIT DEFAULT 0, -- 0: Chưa đạt, 1: Đã đạt
    NgayLamBai DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_KetQuaBaiKiemTra_NguoiDung FOREIGN KEY (MaHocVien) REFERENCES NguoiDung(MaNguoiDung),
    CONSTRAINT FK_KetQuaBaiKiemTra_BaiKiemTra FOREIGN KEY (MaBaiKiemTra) REFERENCES BaiKiemTra(MaBaiKiemTra)
)
GO

-- Tạo bảng TienDoKhoaHoc
CREATE TABLE TienDoKhoaHoc (
    MaTienDoKhoaHoc INT IDENTITY(1,1) PRIMARY KEY,
    MaHocVien INT NOT NULL,
    MaKhoaHoc INT NOT NULL,
    NgayTruyCaosCuoiCung DATETIME,
    PhanTramHoanThanh DECIMAL(5,2) DEFAULT 0.00,
    CONSTRAINT FK_TienDoKhoaHoc_NguoiDung FOREIGN KEY (MaHocVien) REFERENCES NguoiDung(MaNguoiDung),
    CONSTRAINT FK_TienDoKhoaHoc_KhoaHoc FOREIGN KEY (MaKhoaHoc) REFERENCES KhoaHoc(MaKhoaHoc),
    CONSTRAINT UQ_TienDoKhoaHoc UNIQUE (MaHocVien, MaKhoaHoc)
)
GO

-- Tạo bảng TienDoBaiHoc
CREATE TABLE TienDoBaiHoc (
    MaTienDoBaiHoc INT IDENTITY(1,1) PRIMARY KEY,
    MaHocVien INT NOT NULL,
    MaBaiHoc INT NOT NULL,
    DaHoanThanh BIT DEFAULT 0, -- 0: Chưa hoàn thành, 1: Đã hoàn thành
    NgayHoanThanh DATETIME,
    CONSTRAINT FK_TienDoBaiHoc_NguoiDung FOREIGN KEY (MaHocVien) REFERENCES NguoiDung(MaNguoiDung),
    CONSTRAINT FK_TienDoBaiHoc_BaiHoc FOREIGN KEY (MaBaiHoc) REFERENCES BaiHoc(MaBaiHoc),
    CONSTRAINT UQ_TienDoBaiHoc UNIQUE (MaHocVien, MaBaiHoc)
)
GO

-- Tạo bảng ChungChi
CREATE TABLE ChungChi (
    MaChungChi INT IDENTITY(1,1) PRIMARY KEY,
    MaKhoaHoc INT NOT NULL,
    MaHocVien INT NOT NULL,
    NgayCap DATETIME NOT NULL DEFAULT GETDATE(),
    SoChungChi NVARCHAR(50) NOT NULL,
    CONSTRAINT FK_ChungChi_KhoaHoc FOREIGN KEY (MaKhoaHoc) REFERENCES KhoaHoc(MaKhoaHoc),
    CONSTRAINT FK_ChungChi_NguoiDung FOREIGN KEY (MaHocVien) REFERENCES NguoiDung(MaNguoiDung),
    CONSTRAINT UQ_ChungChi UNIQUE (MaKhoaHoc, MaHocVien)
)
GO

-- Tạo bảng ThanhToan
CREATE TABLE ThanhToan (
    MaThanhToan INT IDENTITY(1,1) PRIMARY KEY,
    MaHocVien INT NOT NULL,
    MaKhoaHoc INT NOT NULL,
    SoTien DECIMAL(18,2) NOT NULL,
    NgayThanhToan DATETIME NOT NULL DEFAULT GETDATE(),
    MaTrangThai INT NOT NULL,
    MaGiaoDich NVARCHAR(100),
    PhuongThucThanhToan NVARCHAR(50) NOT NULL,
    CONSTRAINT FK_ThanhToan_NguoiDung FOREIGN KEY (MaHocVien) REFERENCES NguoiDung(MaNguoiDung),
    CONSTRAINT FK_ThanhToan_KhoaHoc FOREIGN KEY (MaKhoaHoc) REFERENCES KhoaHoc(MaKhoaHoc),
    CONSTRAINT FK_ThanhToan_TrangThaiThanhToan FOREIGN KEY (MaTrangThai) REFERENCES TrangThaiThanhToan(MaTrangThai)
)
GO

-- Tạo bảng GioHang
CREATE TABLE GioHang (
    MaGioHang INT IDENTITY(1,1) PRIMARY KEY,
    MaHocVien INT NOT NULL,
    MaKhoaHoc INT NOT NULL,
    NgayThem DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_GioHang_NguoiDung FOREIGN KEY (MaHocVien) REFERENCES NguoiDung(MaNguoiDung),
    CONSTRAINT FK_GioHang_KhoaHoc FOREIGN KEY (MaKhoaHoc) REFERENCES KhoaHoc(MaKhoaHoc),
    CONSTRAINT UQ_GioHang UNIQUE (MaHocVien, MaKhoaHoc)
)
GO

-- Tạo bảng DanhGia
CREATE TABLE DanhGia (
    MaDanhGia INT IDENTITY(1,1) PRIMARY KEY,
    MaKhoaHoc INT NOT NULL,
    MaHocVien INT NOT NULL,
    XepHang INT NOT NULL CHECK (XepHang BETWEEN 1 AND 5),
    BinhLuan NVARCHAR(MAX),
    Ngay DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_DanhGia_KhoaHoc FOREIGN KEY (MaKhoaHoc) REFERENCES KhoaHoc(MaKhoaHoc),
    CONSTRAINT FK_DanhGia_NguoiDung FOREIGN KEY (MaHocVien) REFERENCES NguoiDung(MaNguoiDung),
    CONSTRAINT UQ_DanhGia UNIQUE (MaKhoaHoc, MaHocVien)
)
GO

-- Tạo bảng BaoCao
CREATE TABLE BaoCao (
    MaBaoCao INT IDENTITY(1,1) PRIMARY KEY,
    MaLoaiBaoCao INT NOT NULL,
    NgayTao DATETIME NOT NULL DEFAULT GETDATE(),
    KyHan NVARCHAR(20) NOT NULL, -- 'Ngày', 'Tuần', 'Tháng', 'Quý', 'Năm'
    NoiDungBaoCao NVARCHAR(MAX),
    CONSTRAINT FK_BaoCao_LoaiBaoCao FOREIGN KEY (MaLoaiBaoCao) REFERENCES LoaiBaoCao(MaLoai)
)
GO

-- Tạo bảng GiaoDich
CREATE TABLE GiaoDich (
    MaGiaoDich INT IDENTITY(1,1) PRIMARY KEY,
    MaNguoiDung INT NOT NULL,
    SoTien DECIMAL(18,2) NOT NULL,
    MaLoaiGiaoDich INT NOT NULL,
    Ngay DATETIME NOT NULL DEFAULT GETDATE(),
    MaTrangThaiGiaoDich INT NOT NULL,
    MoTa NVARCHAR(500),
    CONSTRAINT FK_GiaoDich_NguoiDung FOREIGN KEY (MaNguoiDung) REFERENCES NguoiDung(MaNguoiDung),
    CONSTRAINT FK_GiaoDich_LoaiGiaoDich FOREIGN KEY (MaLoaiGiaoDich) REFERENCES LoaiGiaoDich(MaLoai),
    CONSTRAINT FK_GiaoDich_TrangThaiGiaoDich FOREIGN KEY (MaTrangThaiGiaoDich) REFERENCES TrangThaiGiaoDich(MaTrangThai)
)
GO

CREATE TABLE PhienDangNhap (
    SessionID UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    MaNguoiDung INT NOT NULL,
    ThoiGianDangNhap DATETIME NOT NULL DEFAULT GETDATE(),
    ThoiGianKetThuc DATETIME NULL,  -- Có thể dùng để đánh dấu thời gian phiên kết thúc
    IPAddress NVARCHAR(50) NULL,     -- Lưu địa chỉ IP đăng nhập (nếu cần)
    CONSTRAINT FK_PhienDangNhap_NguoiDung FOREIGN KEY (MaNguoiDung)
        REFERENCES NguoiDung(MaNguoiDung)
);
GO