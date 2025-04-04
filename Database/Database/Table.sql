USE Wasko;
GO
DROP TABLE IF EXISTS HocVien_PhuongAn;
GO
DROP TABLE IF EXISTS HocVien_CauHoiTracNghiem;
GO
DROP TABLE IF EXISTS HocVien_BaiKiemTra;
GO
DROP TABLE IF EXISTS HocVien_TaiLieuHocTap;
GO
DROP TABLE IF EXISTS HocVien_BaiHoc;
GO
DROP TABLE IF EXISTS HocVien_KhoaHoc;
GO
DROP TABLE IF EXISTS GopY;
GO
DROP TABLE IF EXISTS PhuongAn;
GO
DROP TABLE IF EXISTS CauHoiTracNghiem;
GO
DROP TABLE IF EXISTS BaiKiemTra;
GO
DROP TABLE IF EXISTS TaiLieuHocTap;
GO
DROP TABLE IF EXISTS BaiHoc;
GO
DROP TABLE IF EXISTS KhoaHoc;
GO
DROP TABLE IF EXISTS ChuDe;
GO
DROP TABLE IF EXISTS QuanTriVien;
GO
DROP TABLE IF EXISTS GiangVien;
GO
DROP TABLE IF EXISTS PhienDangNhap;
GO
DROP TABLE IF EXISTS NguoiDung;
GO
--BẢNG CHÍNH
CREATE TABLE NguoiDung (
    IdNguoiDung INT NOT NULL IDENTITY(1,1),
    TenNguoiDung NVARCHAR(100) NOT NULL,
    VaiTro NVARCHAR(50) NOT NULL DEFAULT N'Học viên'
       CHECK (VaiTro IN (N'Quản trị viên',N'Kiểm duyệt viên',N'Giảng viên',N'Học viên')),
    SoDienThoai NVARCHAR(20) NULL 
		CHECK (SoDienThoai LIKE '0[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
    Email NVARCHAR(100) NULL CONSTRAINT UQ_NguoiDung_Email UNIQUE (Email),
	Salt VARBINARY(16) NOT NULL,
    MatKhau VARBINARY(64) NOT NULL,
    TrangThai NVARCHAR(50) NOT NULL DEFAULT N'Đã đăng ký' CHECK(TrangThai IN (N'Đã đăng ký',N'Đang hoạt động',N'Đã bị khóa')),
    LyDoKhoa NVARCHAR(200) NULL,
    CONSTRAINT PK_NguoiDung PRIMARY KEY (IdNguoiDung)
);
GO
--INSERT NguoiDung VALUES(N'Nguyễn Trung Kiên',N'Quản trị viên',N'0961380804',N'anhthien5487@gmail.com',N'123456',N'Đã đăng ký',NULL)
--SELECT * FROM NguoiDung WHERE VaiTro = N'Quản trị viên'
--INSERT NguoiDung VALUES(N'Nguyễn Đức Huy',N'Giảng viên',NULL,N'nguyenhuy20032003@gmail.com',N'123456',N'Đã đăng ký',NULL)
--INSERT NguoiDung VALUES(N'Hoàng Hồng Đức',N'Kiểm duyệt viên',NULL,N'hoanghongduc609@gmail.com',N'123456',N'Đã đăng ký',NULL)
--SELECT * FROM NguoiDung WHERE VaiTro = N'Kiểm duyệt viên'

CREATE TABLE PhienDangNhap (
    IdPhienDangNhap UNIQUEIDENTIFIER PRIMARY KEY,
    IdNguoiDung INT NOT NULL,
    IdThietBi NVARCHAR(100),
    ThoiDiemDangNhap DATETIME NOT NULL,
    ThoiDiemQuaHan DATETIME NOT NULL,
    FOREIGN KEY (IdNguoiDung) REFERENCES NguoiDung(IdNguoiDung)
);

CREATE TABLE QuanTriVien (
    IdNguoiDung INT NOT NULL,
    PhanTramLoiNhuan INT,
    SoDu INT,
    CONSTRAINT PK_QuanTriVien PRIMARY KEY (IdNguoiDung),
    CONSTRAINT FK_QuanTriVien_NguoiDung 
        FOREIGN KEY (IdNguoiDung) REFERENCES NguoiDung(IdNguoiDung)
        ON DELETE CASCADE
);
GO
--INSERT QuanTriVien VALUES(1,30,NULL)
--SELECT * FROM QuanTriVien INNER JOIN NguoiDung ON QuanTriVien.IdNguoiDung = NguoiDung.IdNguoiDung;

CREATE TABLE GiangVien (
    IdNguoiDung INT NOT NULL,
    SoDu INT,
    CONSTRAINT PK_GiangVien PRIMARY KEY (IdNguoiDung),
    CONSTRAINT FK_GiangVien_NguoiDung 
        FOREIGN KEY (IdNguoiDung) REFERENCES NguoiDung(IdNguoiDung)
        ON DELETE CASCADE
);
GO
--INSERT GiangVien VALUES(2,NULL)
--SELECT * FROM GiangVien INNER JOIN NguoiDung ON GiangVien.IdNguoiDung = NguoiDung.IdNguoiDung;

CREATE TABLE ChuDe (
    IdChuDe INT IDENTITY(1,1) PRIMARY KEY,
    TenChuDe NVARCHAR(255) NOT NULL UNIQUE
);
GO

CREATE TABLE KhoaHoc (
    IdKhoaHoc     INT IDENTITY(1,1) PRIMARY KEY,
	IdBanGoc INT NULL,
    IdGiangVien   INT NOT NULL,
    TenKhoaHoc    NVARCHAR(255) NOT NULL,
    TrangThai     NVARCHAR(50) NOT NULL CHECK (TrangThai IN (N'Đã tạo', N'đang chờ duyệt', N'Đã xuất bản', N'Đã thu hồi')),
    MoTa          NVARCHAR(MAX) NULL,
    NgayTao       DATE NOT NULL DEFAULT GETDATE(),
    NgayXuatBan   DATE NULL,
    IdNguoiDuyet  INT NULL,
    NgayDuyet     DATE NULL,
    IdChuDe       INT NULL,
	CapDo		  NVARCHAR(50) NOT NULL CHECK (CapDo IN (N'Người mới', N'Cơ bản', N'Trung cấp', N'Chuyên sâu', N'Bậc thầy')),
    SoLuongVideo  INT DEFAULT 0,
    GiaKhoaHoc    INT CHECK (GiaKhoaHoc >= 0),
    SoSaoTrungBinh FLOAT DEFAULT 0,
    FOREIGN KEY (IdGiangVien) REFERENCES NguoiDung(IdNguoiDung),
    FOREIGN KEY (IdNguoiDuyet) REFERENCES NguoiDung(IdNguoiDung),
    FOREIGN KEY (IdChuDe) REFERENCES ChuDe(IdChuDe)
);
GO

CREATE TABLE BaiHoc (
    IdBaiHoc   INT IDENTITY(1,1) PRIMARY KEY,
    IdKhoaHoc  INT NOT NULL,
    TenBaiHoc  NVARCHAR(255) NOT NULL,
    MoTa       NVARCHAR(1000) NULL,
    CONSTRAINT FK_BaiHoc_KhoaHoc FOREIGN KEY (IdKhoaHoc) 
        REFERENCES KhoaHoc(IdKhoaHoc) ON DELETE CASCADE
);
GO

CREATE TABLE TaiLieuHocTap(
    IdTaiLieu INT IDENTITY(1,1) PRIMARY KEY,
    IdBaiHoc INT NOT NULL,
    LoaiTaiLieu NVARCHAR(50) CHECK(LoaiTaiLieu IN (N'Tài liệu', N'Video')),
    URL VARCHAR(255) NOT NULL,
    FOREIGN KEY (IdBaiHoc) REFERENCES BaiHoc(IdBaiHoc)
);
GO

CREATE TABLE BaiKiemTra(
    IdBaiKiemTra INT IDENTITY(1,1) PRIMARY KEY,
    IdBaiHoc INT NOT NULL,
    PhanTramDat INT DEFAULT 0 CHECK(PhanTramDat>=0 AND PhanTramDat<=100),
    FOREIGN KEY (IdBaiHoc) REFERENCES BaiHoc(IdBaiHoc) ON DELETE CASCADE
);
GO

CREATE TABLE CauHoiTracNghiem(
    IdCauHoi INT PRIMARY KEY,
    IdBaiKiemTra INT NOT NULL,
    NoiDungCauHoi NVARCHAR(255),
    IdDapAn INT NOT NULL,
    DiemCauHoi INT DEFAULT 10,
    FOREIGN KEY (IdBaiKiemTra) REFERENCES BaiKiemTra(IdBaiKiemTra) ON DELETE CASCADE
);
GO

CREATE TABLE PhuongAn(
    IdPhuongAn INT PRIMARY KEY,
    IdCauHoi INT NOT NULL,
    NoiDungPhuongAn NVARCHAR(255),
    FOREIGN KEY (IdCauHoi) REFERENCES CauHoiTracNghiem(IdCauHoi) ON DELETE CASCADE
);
GO

CREATE TABLE GopY(
    IdGopY INT PRIMARY KEY,
    IdNguoiGopY INT NOT NULL,
    NoiDungGopY NVARCHAR(255),
	NgayGopY DATE NOT NULL DEFAULT GETDATE(),
	TrangThaiGopY NVARCHAR(50) CHECK(TrangThaiGopY IN (N'Đã gửi', N'Đã xem'))
    FOREIGN KEY (IdNguoiGopY) REFERENCES NguoiDung(IdNguoiDung)
);
GO
--BẢNG ĐỆM
CREATE TABLE HocVien_KhoaHoc(
    IdHocVien INT NOT NULL,
	IdKhoaHoc INT NOT NULL,
	TrangThaiKhoaHoc NVARCHAR(50) CHECK(TrangThaiKhoaHoc IN (N'giỏ hàng',N'Đã mua',N'Đã hoàn thành')),
	SoSao INT,
	BinhLuan NVARCHAR(255),

	PRIMARY KEY(IdHocVien,IdKhoaHoc),
	FOREIGN KEY (IdHocVien) REFERENCES NguoiDung(IdNguoiDung),
    FOREIGN KEY (IdKhoaHoc) REFERENCES KhoaHoc(IdKhoaHoc)
);
GO

CREATE TABLE HocVien_BaiHoc(
    IdHocVien INT NOT NULL,
	IdBaiHoc INT NOT NULL,
	PhanTramHoanThanh INT DEFAULT 0,
	TrangThaiBaiHoc NVARCHAR(50) CHECK(TrangThaiBaiHoc IN (N'Chưa hoàn thành',N'Đã hoàn thành')),
	SoSao INT,
	BinhLuan NVARCHAR(255),

	PRIMARY KEY(IdHocVien,IdBaiHoc),
	FOREIGN KEY (IdHocVien) REFERENCES NguoiDung(IdNguoiDung),
    FOREIGN KEY (IdBaiHoc) REFERENCES BaiHoc(IdBaiHoc)
);
GO

CREATE TABLE HocVien_TaiLieuHocTap(
    IdHocVien INT NOT NULL,
	IdTaiLieu INT NOT NULL,
	PhanTramXem INT DEFAULT 0,
	TrangThaiTaiLieu NVARCHAR(50) CHECK(TrangThaiTaiLieu IN (N'Chưa xem',N'Đã xem')),

	PRIMARY KEY(IdHocVien,IdTaiLieu),
	FOREIGN KEY (IdHocVien) REFERENCES NguoiDung(IdNguoiDung),
    FOREIGN KEY (IdTaiLieu) REFERENCES TaiLieuHocTap(IdTaiLieu)
);
GO

CREATE TABLE HocVien_BaiKiemTra(
    IdHocVien INT NOT NULL,
	IdBaiKiemTra INT NOT NULL,
	DiemDatDuoc INT CHECK(DiemDatDuoc>=0 AND DiemDatDuoc<=100),
	TrangThaiBaiKiemTra NVARCHAR(50) CHECK(TrangThaiBaiKiemTra IN (N'Chưa đạt',N'Đã đạt')),
	SoSao INT,
	BinhLuan NVARCHAR(255),

	PRIMARY KEY(IdHocVien,IdBaiKiemTra),
	FOREIGN KEY (IdHocVien) REFERENCES NguoiDung(IdNguoiDung),
    FOREIGN KEY (IdBaiKiemTra) REFERENCES BaiKiemTra(IdBaiKiemTra)
);
GO

CREATE TABLE HocVien_CauHoiTracNghiem(
    IdHocVien INT NOT NULL,
	IdCauHoiTracNghiem INT NOT NULL,
	TrangThaiCauHoiTracNghiem NVARCHAR(50) CHECK(TrangThaiCauHoiTracNghiem IN (N'Chưa làm',N'Đã làm')),

	PRIMARY KEY(IdHocVien,IdCauHoiTracNghiem),
	FOREIGN KEY (IdHocVien) REFERENCES NguoiDung(IdNguoiDung),
    FOREIGN KEY (IdCauHoiTracNghiem) REFERENCES CauHoiTracNghiem(IdCauHoi)
);
GO

CREATE TABLE HocVien_PhuongAn(
    IdHocVien INT NOT NULL,
	IdPhuongAn INT NOT NULL,
	TrangThaiPhuongAn NVARCHAR(50) CHECK(TrangThaiPhuongAn IN (N'Đúng',N'Sai')),

	PRIMARY KEY(IdHocVien,IdPhuongAn),
	FOREIGN KEY (IdHocVien) REFERENCES NguoiDung(IdNguoiDung),
    FOREIGN KEY (IdPhuongAn) REFERENCES PhuongAn(IdPhuongAn)
);
GO