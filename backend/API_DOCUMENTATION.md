# TÀI LIỆU CHI TIẾT TOÀN BỘ API BACKEND (AUTO RENTAL)
**Dự án:** Ứng dụng Thuê xe Tự lái & Kèm Tài xế (PRM393)  
**Địa chỉ Base URL:** `http://localhost:8080` (trên máy ảo Android dùng `http://10.0.2.2:8080`)

---

## MỤC LỤC
1. [Phân hệ 1: Xác thực & Tài khoản (Auth)](#1-phân-hệ-xác-thực--tài-khoản-auth)
2. [Phân hệ 2: Quản lý Xe (Vehicles)](#2-phân-hệ-quản-lý-xe-vehicles)
3. [Phân hệ 3: Thuật toán Matching % (Matching Engine)](#3-phân-hệ-thuật-toán-matching--matching-engine)
4. [Phân hệ 4: Đặt xe & Thuê kèm tài xế (Bookings)](#4-phân-hệ-đặt-xe--thuê-kèm-tài-xế-bookings)
5. [Phân hệ 5: Thanh toán cọc & Hóa đơn (Payments)](#5-phân-hệ-thanh-toán-cọc--hóa-đơn-payments)
6. [Phân hệ 6: Thẩm định Tình trạng xe Before/After (Inspection)](#6-phân-hệ-thẩm-định-tình-trạng-xe-beforeafter-inspection)
7. [Phân hệ 7: Giám sát GPS, Bảo vệ riêng tư & Quota 20 lần (GPS & Privacy)](#7-phân-hệ-giám-sát-gps-bảo-vệ-riêng-tư--quota-20-lần-gps--privacy)
8. [Phân hệ 8: Hệ thống Thông báo (Notifications)](#8-phân-hệ-hệ-thống-thông-báo-notifications)
9. [Phân hệ 9: Tải file ảnh cục bộ (File Upload)](#9-phân-hệ-tải-file-ảnh-cục-bộ-file-upload)

---

## 1. Phân hệ Xác thực & Tài khoản (Auth)

### 1.1. Đăng ký tài khoản
* **Endpoint:** `POST /api/auth/register`
* **Mục đích:** Tạo tài khoản mới cho người dùng, lưu trữ số CCCD và Giấy phép lái xe (GPLX).
* **Phân quyền:** Public (Không cần Token).
* **Request Body:**
  ```json
  {
    "fullName": "Nguyễn Văn A",
    "email": "nguyenvana@gmail.com",
    "phone": "0987654321",
    "password": "mypassword123",
    "role": "ROLE_RENTER", // hoặc ROLE_OWNER, ROLE_BOTH
    "cccdNumber": "001202009988",
    "driverLicense": "B2-123456"
  }
  ```
* **Ý nghĩa xử lý ngầm:** Kiểm tra trùng email/SĐT, mã hóa mật khẩu bằng BCrypt trước khi lưu vào DB.

### 1.2. Đăng nhập
* **Endpoint:** `POST /api/auth/login`
* **Mục đích:** Xác thực tài khoản và cấp mã JWT Token để client gắn vào các request sau.
* **Phân quyền:** Public.
* **Request Body:**
  ```json
  {
    "username": "owner@gmail.com", // Đăng nhập bằng Email hoặc SĐT đều được
    "password": "123456"
  }
  ```
* **Dữ liệu trả về:** Chuỗi `token` dạng JWT Bearer, thông tin cơ bản của User và `role`.

### 1.3. Lấy thông tin cá nhân hiện tại
* **Endpoint:** `GET /api/auth/me`
* **Mục đích:** App dùng để lấy thông tin người dùng đang đăng nhập và hiển thị lên màn hình Profile.
* **Headers:** `Authorization: Bearer <token>`

### 1.4. Chuyển đổi vai trò (Switch Mode)
* **Endpoint:** `PUT /api/auth/switch-role`
* **Mục đích:** Cho phép người dùng chuyển nhanh giữa giao diện **Khách thuê (Renter)** và **Chủ xe (Owner)**.
* **Request Body:** `{"target_role": "ROLE_OWNER"}`

---

## 2. Phân hệ Quản lý Xe (Vehicles)

### 2.1. Lấy danh sách tất cả xe sẵn sàng cho thuê
* **Endpoint:** `GET /api/vehicles`
* **Mục đích:** Màn hình Khám phá hiển thị danh sách tất cả xe có trạng thái `AVAILABLE`.
* **Phân quyền:** Public (Khách chưa đăng nhập vẫn xem được danh sách xe).

### 2.2. Chủ xe đăng xe mới (Hỗ trợ cấu hình Có Tài Xế)
* **Endpoint:** `POST /api/vehicles`
* **Mục đích:** Chủ xe đăng thông tin xe, thiết lập giá thuê và **cấu hình tùy chọn có tài xế**.
* **Headers:** `Authorization: Bearer <TOKEN_OWNER>`
* **Request Body:**
  ```json
  {
    "name": "VinFast VF8 Plus",
    "brand": "VinFast",
    "model_year": 2023,
    "license_plate": "30K-888.88",
    "vehicle_type": "SUV", // SEDAN, SUV, MPV, HATCHBACK, PICKUP
    "transmission": "AUTO", // AUTO, MANUAL
    "fuel_type": "ELECTRIC", // PETROL, DIESEL, ELECTRIC, HYBRID
    "base_price_per_day": 1200000,
    "has_driver_option": true,  // Cờ: Có hỗ trợ thuê kèm tài xế không
    "driver_fee_per_day": 450000, // Phụ phí thuê tài xế/ngày
    "seats": 5,
    "address": "Hòa Lạc, Hà Nội",
    "current_lat": 21.0131,
    "current_lng": 105.5255,
    "thumbnail_url": "http://localhost:8080/uploads/vehicles/vf8.jpg"
  }
  ```

### 2.3. Lấy danh sách xe của chính chủ xe
* **Endpoint:** `GET /api/vehicles/owner`
* **Mục đích:** Màn hình "Quản lý xe của tôi" của Chủ xe hiển thị danh sách các xe do mình đăng tải và tình trạng hiện tại (Đang trống, Đang cho thuê, Đang bảo dưỡng).
* **Headers:** `Authorization: Bearer <TOKEN_OWNER>`

### 2.4. Xem chi tiết 1 xe
* **Endpoint:** `GET /api/vehicles/{id}`
* **Mục đích:** Xem thông số kỹ thuật đầy đủ, mô tả chi tiết và danh sách ảnh của xe.

---

## 3. Phân hệ Thuật toán Matching % (Matching Engine)

### 3.1. Tìm kiếm xe theo tỉ lệ phù hợp (Matching)
* **Endpoint:** `POST /api/vehicles/match`
* **Mục đích:** Khách thuê nhập nhu cầu và kéo thanh trượt điều chỉnh độ ưu tiên (ngân sách, vị trí gần tôi, cần tài xế...). Hệ thống tự động tính điểm từ **0 đến 100%** và xếp hạng xe phù hợp nhất lên đầu.
* **Request Body:**
  ```json
  {
    "budget": 1200000,        // Ngân sách dự kiến/ngày
    "need_driver": true,      // Cần thuê cả lái xe
    "user_lat": 21.0131,      // Toạ độ vị trí người thuê
    "user_lng": 105.5255,
    "vehicle_type": "SUV",    // Loại xe mong muốn
    "budget_weight": 0.25,    // Trọng số ngân sách (thanh kéo slider)
    "distance_weight": 0.20,  // Trọng số khoảng cách gần nhà
    "driver_weight": 0.30     // Trọng số cần lái xe
  }
  ```
* **Ý nghĩa dữ liệu trả về:**
  * `match_score`: Điểm phần trăm (ví dụ: `95.4%`).
  * `match_label`: Nhãn hiển thị badge (`Rất phù hợp (95.4%)`).
  * `distance_km`: Khoảng cách từ khách đến xe tính theo công thức Haversine.
  * `breakdown_scores`: Chi tiết điểm từng tiêu chí (tiền, khoảng cách, tài xế...).

---

## 4. Phân hệ Đặt xe & Thuê kèm tài xế (Bookings)

### 4.1. Tạo yêu cầu đặt xe
* **Endpoint:** `POST /api/bookings`
* **Mục đích:** Khách thuê đặt xe, chọn khoảng thời gian và tick chọn **"Thuê cả lái xe"**.
* **Headers:** `Authorization: Bearer <TOKEN_RENTER>`
* **Request Body:**
  ```json
  {
    "vehicle_id": 1,
    "start_date": "2026-11-05T08:00:00",
    "end_date": "2026-11-07T08:00:00",
    "with_driver": true, // Tick chọn thuê cả lái xe
    "pickup_address": "Khu CNC Hòa Lạc, Hà Nội",
    "return_address": "Khu CNC Hòa Lạc, Hà Nội"
  }
  ```
* **Ý nghĩa xử lý ngầm tại Backend:**
  * Tính số ngày: $7 - 5 = 2\text{ ngày}$.
  * Tiền thuê xe: `basePricePerDay * 2`.
  * Phụ phí tài xế: `driverFeePerDay * 2` (nếu `with_driver = false` thì $= 0$).
  * Tổng tiền: `carRentalPrice + driverServicePrice`.
  * Tiền cọc: $30\%$ của tổng tiền.
  * Tự động gửi thông báo cho Chủ xe: *"Có khách vừa đặt xe..."*.

### 4.2. Chủ xe duyệt đơn thuê xe
* **Endpoint:** `PUT /api/bookings/{id}/confirm`
* **Mục đích:** Chủ xe bấm duyệt đơn thuê $\rightarrow$ Xe chuyển sang trạng thái `RENTED`, đơn chuyển sang `CONFIRMED`. Đồng thời gửi thông báo duyệt đơn về máy khách thuê.

### 4.3. Bắt đầu chuyến đi (Start Trip)
* **Endpoint:** `PUT /api/bookings/{id}/start`
* **Mục đích:** Khi khách nhận xe bắt đầu di chuyển, đơn chuyển sang trạng thái `ONGOING` và kích hoạt mốc thời gian giám sát GPS.

### 4.4. Hoàn thành chuyến xe (Complete Trip)
* **Endpoint:** `PUT /api/bookings/{id}/complete`
* **Mục đích:** Sau khi kiểm tra đối chiếu xe hoàn tất, đơn chuyển sang `COMPLETED`, xe tự động chuyển về `AVAILABLE` để đón khách tiếp theo.

### 4.5. Xem danh sách đơn thuê của tôi
* Khách thuê: `GET /api/bookings/renter`
* Chủ xe: `GET /api/bookings/owner`

---

## 5. Phân hệ Thanh toán cọc & Hóa đơn (Payments)

### 5.1. Xử lý thanh toán cọc / thanh toán hóa đơn
* **Endpoint:** `POST /api/payments/checkout`
* **Mục đích:** Khách thuê thanh toán tiền đặt cọc (30%) hoặc thanh toán số tiền còn lại sau khi kết thúc chuyến đi.
* **Headers:** `Authorization: Bearer <TOKEN_RENTER>`
* **Request Body:**
  ```json
  {
    "booking_id": 1,
    "amount": 990000,
    "payment_type": "DEPOSIT", // hoặc "FINAL_PAYMENT"
    "payment_method": "BANK_TRANSFER_QR" // "CASH", "VNPAY_MOCK"
  }
  ```
* **Ý nghĩa xử lý ngầm tại Backend:**
  * Lưu bản ghi thanh toán vào bảng `payments` với trạng thái `SUCCESS`.
  * Tự động gửi thông báo cho Chủ xe: *"Khách hàng vừa thanh toán cọc 990.000 đ cho đơn #1"*.

### 5.2. Lấy lịch sử giao dịch thanh toán của đơn thuê
* **Endpoint:** `GET /api/payments/booking/{bookingId}`
* **Mục đích:** Tra cứu lịch sử thanh toán của một chuyến đi (đã cọc bao nhiêu, đã trả bao nhiêu, hoàn cọc bao nhiêu) hiển thị lên màn hình Hóa đơn / Checkout.
* **Headers:** `Authorization: Bearer <token>`

---

## 6. Phân hệ Thẩm định Tình trạng xe Before/After (Inspection)

### 5.1. Lưu biên bản ảnh thẩm định xe
* **Endpoint:** `POST /api/inspections`
* **Mục đích:** Lưu 6 góc ảnh tiêu chuẩn cùng số km ODO và % vạch xăng/pin tại 2 thời điểm:
  * `CHECK_IN`: Chụp lúc giao/nhận xe ban đầu.
  * `CHECK_OUT`: Chụp lúc hoàn trả xe mới.
* **Request Body:**
  ```json
  {
    "booking_id": 1,
    "stage": "CHECK_IN", // hoặc "CHECK_OUT"
    "front_img": "http://localhost:8080/uploads/inspections/front.jpg",
    "rear_img": "http://localhost:8080/uploads/inspections/rear.jpg",
    "left_img": "http://localhost:8080/uploads/inspections/left.jpg",
    "right_img": "http://localhost:8080/uploads/inspections/right.jpg",
    "odo_img": "http://localhost:8080/uploads/inspections/odo.jpg",
    "fuel_img": "http://localhost:8080/uploads/inspections/fuel.jpg",
    "odo_km": 15000.0,
    "fuel_level_percent": 100.0,
    "notes": "Xe sạch sẽ, không trầy xước"
  }
  ```

### 5.2. Lấy dữ liệu đối chiếu Trước & Sau (Before - After Comparison)
* **Endpoint:** `GET /api/inspections/{bookingId}/comparison`
* **Mục đích:** Trả về dữ liệu cho màn hình so sánh đối chiếu:
  * Hiển thị ảnh `check_in` bên cạnh ảnh `check_out` để phát hiện xước xát phát sinh.
  * Tự tính sẵn:
    * `odo_difference_km`: Số km thực tế đã chạy trong chuyến đi.
    * `fuel_difference_percent`: Chênh lệch nhiên liệu để tính phụ phí nếu khách trả xe thiếu xăng.

### 5.3. Bấm xác nhận biên bản thẩm định
* **Endpoint:** `PUT /api/inspections/{id}/confirm`
* **Mục đích:** Chủ xe hoặc Khách thuê bấm xác nhận đồng ý với hiện trạng xe. Khi cả 2 bên cùng xác nhận thì biên bản được chốt hoàn tất.

---

## 7. Phân hệ Giám sát GPS, Bảo vệ riêng tư & Quota 20 lần (GPS & Privacy)

### 6.1. Người thuê xe gửi toạ độ GPS (GPS Ping)
* **Endpoint:** `POST /api/gps/ping`
* **Mục đích:** Thiết bị người thuê gửi toạ độ hiện tại của xe về server.
* **Ràng buộc nghiệp vụ:** **Tối đa 1 tiếng phải gửi 1 lần**. Mỗi lần gửi sẽ cập nhật mốc `last_renter_gps_ping = now()`.

### 6.2. Người thuê xe xem FULL lộ trình di chuyển
* **Endpoint:** `GET /api/gps/renter-route/{bookingId}`
* **Mục đích:** Lấy toàn bộ danh sách toạ độ xe đã đi qua để vẽ đường Polyline trên Google Maps.
* **Bảo mật:** Chỉ người thuê chuyến xe này mới được quyền gọi API này.

### 6.3. Chủ xe xem vị trí tức thời (Bảo vệ riêng tư & Quota 20 lần/ngày)
* **Endpoint:** `GET /api/gps/owner-snapshot/{bookingId}`
* **Mục đích:** Chủ xe kiểm tra xem xe mình đang ở đâu.
* **Quy tắc bảo mật riêng tư:**
  * **Tuyệt đối KHÔNG trả về lịch sử đường đi (no route history)** để bảo vệ quyền riêng tư cá nhân của khách thuê.
  * Chỉ trả về 1 toạ độ điểm mới nhất + tốc độ hiện tại.
* **Quy tắc Giới hạn (Rate-limiting):**
  * Tối đa **20 lần / ngày**.
  * Dữ liệu trả về có trường `remaining_checks_today` đếm lùi: $20 \rightarrow 19 \rightarrow 18...$
  * Nếu check lần thứ 21 trong ngày $\rightarrow$ Server chặn ngay lập tức và trả về mã lỗi:
    `HTTP 429 Too Many Requests: Bạn đã dùng hết 20 lượt kiểm tra vị trí xe trong ngày hôm nay.`

### 6.4. Kiểm tra trạng thái ping GPS 1 tiếng
* **Endpoint:** `GET /api/gps/status/{bookingId}`
* **Mục đích:** Kiểm tra xem người thuê có tuân thủ quy định bật GPS không. Nếu $(now - lastPing) > 60\text{ phút} \rightarrow$ Trả về `is_overdue: true` kèm thông báo cảnh báo vi phạm.
* **Cơ chế nền:** `GpsMonitorScheduler` trong backend tự động quét 15 phút/lần, nếu quá 1 tiếng sẽ tự động gửi Notification cảnh báo.

---

## 8. Phân hệ Hệ thống Thông báo (Notifications)

### 7.1. Lấy danh sách thông báo của người dùng
* **Endpoint:** `GET /api/notifications`
* **Mục đích:** Hiển thị danh sách thông báo trên chuông thông báo của App (Cảnh báo GPS, thông báo duyệt đơn, cập nhật bàn giao xe).

### 7.2. Đánh dấu đã đọc
* **Endpoint:** `PUT /api/notifications/{id}/read`

### 7.3. Lấy số lượng thông báo chưa đọc
* **Endpoint:** `GET /api/notifications/unread-count`
* **Mục đích:** Hiển thị số badge đỏ trên biểu tượng quả chuông thông báo (ví dụ: `(3)`).

---

## 9. Phân hệ Tải file ảnh cục bộ (File Upload)

### 8.1. Upload ảnh chụp từ điện thoại lên Server
* **Endpoint:** `POST /api/files/upload?folder=vehicles` hoặc `?folder=inspections`
* **Body:** `form-data` gồm trường `file` (chọn file ảnh `.jpg`/`.png`).
* **Mục đích:** Lưu ảnh trực tiếp vào ổ cứng backend (`backend/uploads/...`) và trả về URL để hiển thị trên ứng dụng di động:
  `http://localhost:8080/uploads/inspections/ten_file.jpg`.

