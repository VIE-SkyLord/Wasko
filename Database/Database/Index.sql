-- Index cho bảng NguoiDung
CREATE NONCLUSTERED INDEX IX_NguoiDung_Email ON NguoiDung(Email);
CREATE NONCLUSTERED INDEX IX_NguoiDung_VaiTro ON NguoiDung(VaiTro);

-- Index cho bảng KhoaHoc
CREATE NONCLUSTERED INDEX IX_KhoaHoc_IdGiangVien ON KhoaHoc(IdGiangVien);
CREATE NONCLUSTERED INDEX IX_KhoaHoc_TrangThai ON KhoaHoc(TrangThai);
CREATE NONCLUSTERED INDEX IX_KhoaHoc_IdChuDe ON KhoaHoc(IdChuDe);

-- Index cho bảng BaiHoc
CREATE NONCLUSTERED INDEX IX_BaiHoc_IdKhoaHoc ON BaiHoc(IdKhoaHoc);

-- Index cho bảng HocVien_KhoaHoc
CREATE NONCLUSTERED INDEX IX_HocVien_KhoaHoc_TrangThaiKhoaHoc ON HocVien_KhoaHoc(TrangThaiKhoaHoc);