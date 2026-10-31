# AUTO RENTAL BACKEND SERVICE (JAVA SPRING BOOT 3)
Dự án Backend cho Hệ thống Cho Thuê Xe - Môn học **PRM393** (Đại học FPT)

---

## 1. Hướng Dẫn Cài Đặt & Chạy Cục Bộ (Local)

### Yêu cầu môi trường:
- **Java:** JDK 17 hoặc JDK 21
- **Maven:** 3.8+
- **Cơ sở dữ liệu:** MySQL (hoặc MariaDB). Mặc định cấu hình kết nối tới database `autorental_db` (tự động tạo database nếu chưa có).

### Các bước khởi chạy:
1. Mở file `.env` hoặc file `src/main/resources/application.properties` để kiểm tra tài khoản MySQL của bạn:
   ```properties
   DB_HOST=localhost
   DB_PORT=3306
   DB_NAME=autorental_db
   DB_USERNAME=root
   DB_PASSWORD=root
   ```
2. Mở terminal tại thư mục `backend/` và gõ lệnh:
   ```bash
   mvn clean spring-boot:run
   ```
3. Khi server khởi động thành công:
   - Cổng mặc định: `http://localhost:8080` (trên Android Emulator truy cập qua `http://10.0.2.2:8080`).
   - Hệ thống tự động kích hoạt `DataSeeder` tạo sẵn tài khoản test và xe mẫu.

---

## 2. Tài Khoản Test Mẫu Sẵn Có

| Vai trò | Email đăng nhập | Mật khẩu | Chức năng thử nghiệm |
| :--- | :--- | :---: | :--- |
| **Chủ xe (Owner)** | `owner@gmail.com` | `123456` | Đăng xe, duyệt đơn, xem vị trí tức thời (bị giới hạn 20 lần/ngày), đối chiếu ảnh Before/After. |
| **Khách thuê (Renter)** | `renter@gmail.com` | `123456` | Tìm xe, điều chỉnh slider Matching %, đặt xe có/không tài xế, chụp ảnh nhận xe, ping GPS & xem full lộ trình. |

---

## 3. Danh Sách API Phục Vụ 4 Nghiệp Vụ Cốt Lõi

### 3.1. Xác thực & Phân quyền (Auth)
- `POST /api/auth/register` : Đăng ký người dùng (hỗ trợ nhập CCCD, GPLX).
- `POST /api/auth/login` : Đăng nhập nhận JWT Token.
- `PUT /api/auth/switch-role` : Chuyển đổi vai trò RENTER / OWNER.
- `GET /api/auth/me` : Lấy thông tin cá nhân.

### 3.2. Nghiệp vụ 1: Đa vai trò & Thuê kèm tài xế (With Driver)
- `POST /api/vehicles` : Chủ xe đăng xe (bật cờ `has_driver_option: true` và nhập `driver_fee_per_day`).
- `GET /api/vehicles` : Danh sách tất cả xe đang sẵn sàng.
- `POST /api/bookings` : Khách đặt xe, bật cờ `with_driver: true`. Backend tự động tính tiền:
  $$\text{total\_price} = (\text{base\_price} \times \text{days}) + (\text{driver\_fee} \times \text{days})$$
- `PUT /api/bookings/{id}/confirm` : Chủ xe duyệt đơn.

### 3.3. Nghiệp vụ 2: Giám sát GPS, Bảo vệ Quyền riêng tư & Quota 20 lần/ngày
- `POST /api/gps/ping` : Khách thuê gửi toạ độ GPS (Cập nhật vị trí và mốc thời gian ping).
- `GET /api/gps/renter-route/{bookingId}` : **Khách thuê xem FULL lộ trình** (Danh sách toàn bộ các toạ độ để vẽ Polyline trên Google Maps).
- `GET /api/gps/owner-snapshot/{bookingId}` : **Chủ xe xem toạ độ tức thời**:
  - Tuyệt đối không trả về lịch sử lộ trình.
  - Tự động trừ lượt: tối đa **20 lần / ngày**. Nếu hết lượt $\rightarrow$ Trả về `HTTP 429 Too Many Requests`.
- `GET /api/gps/status/{bookingId}` : Kiểm tra nếu quá 60 phút khách chưa ping GPS $\rightarrow$ Trả về `is_overdue: true`. Đồng thời có `GpsMonitorScheduler` tự động quét định kỳ gửi thông báo cảnh báo.

### 3.4. Nghiệp vụ 3: Thẩm định Tình trạng xe (Vehicle Inspection Before/After)
- `POST /api/files/upload?folder=inspections` : Tải ảnh chụp từ điện thoại lên lưu trữ cục bộ.
- `POST /api/inspections` : Gửi biên bản thẩm định gồm 6 góc chụp (Đầu, Đuôi, 2 Bên, ODO, Xăng) cho giai đoạn `CHECK_IN` hoặc `CHECK_OUT`.
- `GET /api/inspections/{bookingId}/comparison` : **Lấy dữ liệu đối chiếu Before - After** trả về song song ảnh lúc nhận và lúc trả, độ chênh lệch km ODO và % nhiên liệu.
- `PUT /api/inspections/{id}/confirm` : Khách hoặc Chủ xe bấm xác nhận biên bản.

### 3.5. Nghiệp vụ 4: Thuật toán Matching & Tỉ lệ khớp %
- `POST /api/vehicles/match` :
  - **Body:** `{ "budget": 1000000, "need_driver": true, "user_lat": 21.013, "user_lng": 105.525, "budget_weight": 0.25, "distance_weight": 0.20, "driver_weight": 0.30 }`
  - **Response:** Danh sách xe sắp xếp theo `match_score` (từ 0 - 100%) kèm nhãn (`match_label`) và chi tiết điểm từng tiêu chí (`breakdown_scores`).

### 3.6. Thông báo (Notifications)
- `GET /api/notifications` : Danh sách thông báo (cảnh báo GPS, cập nhật đơn thuê).
- `PUT /api/notifications/{id}/read` : Đánh dấu đã đọc.
- `GET /api/notifications/unread-count` : Số lượng thông báo chưa đọc.

