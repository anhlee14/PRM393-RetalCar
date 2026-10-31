# HỆ THỐNG CHO THUÊ XE TỰ LÁI & KÈM TÀI XẾ (AUTORENTAL)
**Môn học:** PRM393 - Lập trình Di động (Flutter & Dart) - Đại học FPT  
**Thư mục làm việc:** `Group_Project/`

---

## 1. Cấu Trúc Tổng Quan Dự Án
```text
Group_Project/
├── backend/                     # BACKEND: Java Spring Boot 3.2.4 (Chuẩn kiến trúc ls12-backend)
│   ├── src/main/java/           # Controller, Service, Model, Repository, Security + JWT
│   ├── uploads/                 # Lưu trữ file ảnh xe & ảnh thẩm định cục bộ (không cần Cloudinary)
│   ├── pom.xml                  # Quản lý thư viện Maven
│   └── README.md                # Hướng dẫn chi tiết chạy Backend & Tài liệu API
│
└── frontend/                    # FRONTEND: Flutter 3.x (Clean Architecture chia theo Feature)
    ├── lib/
    │   ├── core/                # Constants (API endpoints), Network (ApiClient gắn JWT), Utils
    │   ├── data/                # Data Models & Services gọi API xuống Backend
    │   ├── features/            # CÁC MODULE CHIA CHO 3 THÀNH VIÊN TRONG NHÓM
    │   │   ├── auth/            # 👤 Thành viên 1: Đăng nhập, Đăng ký, Đổi role Renter/Owner
    │   │   ├── vehicle_management/ # 👤 Thành viên 1: Chủ xe đăng xe & cấu hình có tài xế
    │   │   ├── matching_explore/# 👤 Thành viên 2: Danh sách xe, Thẻ % Matching, Sliders độ ưu tiên
    │   │   ├── booking/         # 👤 Thành viên 2: Đặt xe, chọn ngày, tính tiền có tài xế, Checkout cọc
    │   │   ├── inspection/      # 👤 Thành viên 3: Chụp 6 góc xe, Màn hình đối chiếu Before/After
    │   │   └── gps_tracking/    # 👤 Thành viên 3: Renter xem full route, Chủ xe xem 1 điểm + Quota 20, Thông báo
    │   └── main.dart            # Màn hình khởi chạy đăng nhập chuẩn kết nối API
    └── pubspec.yaml
```

---

## 2. Hướng Dẫn Chạy Thử Nghiệm

### Bước 1: Khởi động Backend (Java Spring Boot)
1. Mở terminal tại thư mục `backend/`:
   ```bash
   cd backend
   mvn spring-boot:run
   ```
2. Server chạy tại `http://localhost:8080` (hoặc `http://10.0.2.2:8080` trên Android Emulator).
3. Tài khoản test tự động sinh:
   - **Chủ xe:** `owner@gmail.com` / `123456`
   - **Khách thuê:** `renter@gmail.com` / `123456`

### Bước 2: Khởi động Frontend (Flutter Mobile App)
1. Mở terminal tại thư mục `frontend/`:
   ```bash
   cd frontend
   flutter run
   ```
2. Ứng dụng sẽ hiển thị thanh điều hướng 4 Tab và màn hình Khám phá xe mẫu có kết nối API.

---

## 3. Phân Công Công Việc Trong Nhóm (WBS)
Mỗi thành viên mở thư mục `features/<tên_module>/README.md` tương ứng để xem chi tiết danh sách màn hình cần vẽ và API cần kết nối.

