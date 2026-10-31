# PHÂN HỆ: ĐỊNH VỊ GPS, BẢO VỆ RIÊNG TƯ & THÔNG BÁO (GPS & PRIVACY)
**Người phụ trách:** 👤 **Thành viên 3**  
**Môn học:** PRM393 - Mobile Application Development (FPT University)

---

## 1. Danh Sách Màn Hình Cần Tạo (`lib/features/gps_tracking/screens/`):

### 1.1. `renter_route_map_screen.dart` : Bản Đồ Lộ Trình Của Khách Thuê
- **Mục tiêu:** Thực hiện **Nghiệp vụ đặc thù 2**, cho phép khách thuê xem toàn bộ lịch sử di chuyển và tuân thủ quy định gửi toạ độ tối đa 60 phút/lần.
- **Thành phần giao diện:**
  1. **Khung Bản Đồ Lộ Trình Đầy Đủ (Full Route Visualization):**
     - Hiển thị danh sách các toạ độ xe đã đi qua.
     - Vẽ đường nối các điểm di chuyển (hoặc danh sách toạ độ breadcrumbs theo thời gian).
     - Huy hiệu góc: *"Chỉ khách thuê mới có quyền xem toàn bộ lộ trình này"*.
  2. **Banner Cảnh Báo Quy Định 1 Tiếng (Quy định bắt buộc hợp đồng):**
     - Gọi `GpsService.checkGpsStatus(bookingId)`.
     - Nếu `is_overdue == true` (đã quá 60 phút chưa gửi toạ độ):
       - Viền và nền chuyển sang màu đỏ rực: *"⚠️ CẢNH BÁO: Đã X phút bạn chưa cập nhật toạ độ GPS. Vui lòng gửi vị trí ngay để tránh bị phạt vi phạm hợp đồng!"*.
     - Nếu bình thường: Khung xanh lá *"✅ Tình trạng GPS hợp lệ. Lần cập nhật gần nhất: X phút trước"*.
  3. **Nút Nổi (FAB): "GỬI VỊ TRÍ HIỆN TẠI (PING GPS)":**
     - Khi bấm: Lấy toạ độ thiết bị (hoặc toạ độ giả lập) và gọi `GpsService.pingGps(bookingId, latitude, longitude, speed)`.
     - Tự động reset lại bộ đếm giờ 60 phút về 0 và cập nhật thêm 1 mốc toạ độ mới vào danh sách.
  4. Lịch sử các mốc toạ độ (`ListView`): Hiển thị toạ độ (Kinh độ, Vĩ độ), tốc độ (km/h) và thời gian ghi nhận.

---

### 1.2. `owner_snapshot_screen.dart` : Bản Đồ Hiện Trạng Xe Của Chủ Xe (Bảo Vệ Quyền Riêng Tư)
- **Mục tiêu:** Thực hiện **Nghiệp vụ đặc thù 2 (Chính sách riêng tư chuẩn GDPR)**, bảo đảm chủ xe không theo dõi lén khách thuê.
- **Quy tắc bảo mật bắt buộc:**
  - **TUYỆT ĐỐI KHÔNG HIỂN THỊ ĐƯỜNG ĐI (NO ROUTE / NO POLYLINE).**
  - Chỉ hiển thị duy nhất **1 Marker vị trí tức thời (Snapshot)** của xe tại thời điểm kiểm tra.
- **Thành phần giao diện:**
  1. **Thanh Đo Quota Giới Hạn 20 Lượt / Ngày:**
     - Hiển thị nổi bật: *"Bạn còn `remainingChecksToday` / 20 lượt kiểm tra vị trí hôm nay"*.
     - Thanh Progress bar đo tỉ lệ lượt còn lại.
     - Cảnh báo: Mỗi lần nhấn "Làm mới vị trí" sẽ bị trừ đi 1 lượt check.
  2. Thẻ Xe & Vị trí tức thời: Tên xe, biển số, tốc độ hiện tại (km/h), thời gian cập nhật.
  3. **Hộp thoại Khóa Hạn Ngạch khi Quá 20 Lượt (HTTP 429):**
     - Khi `remainingChecksToday <= 0` hoặc Backend trả về lỗi mã 429:
       - Vô hiệu hoá nút làm mới.
       - Hiển thị thông báo màu đỏ: *"Bạn đã sử dụng hết 20 lượt kiểm tra vị trí trong ngày hôm nay theo chính sách bảo mật quyền riêng tư của khách thuê. Lượt kiểm tra sẽ được cấp lại vào 00:00 ngày mai."*
  4. Nút bấm: *"LÀM MỚI VỊ TRÍ (-1 LƯỢT CHECK)"* $\rightarrow$ Gọi `GpsService.getOwnerSnapshot(bookingId)`.

---

### 1.3. `notifications_screen.dart` : Màn Hình Chuông Thông Báo Hệ Thống
- **Mục tiêu:** Tiếp nhận và hiển thị các cảnh báo tự động từ hệ thống.
- **Thành phần giao diện:**
  1. AppBar: *"Thông Báo Hệ Thống"*, nút Tải lại.
  2. Danh sách thông báo dạng thẻ (`ListView.builder`):
     - Icon và màu sắc phân loại:
       - 🚨 Đỏ: Cảnh báo quá 1 tiếng chưa bật GPS (`GPS_WARNING`).
       - 📝 Xanh dương: Thông báo duyệt đơn đặt xe (`BOOKING_STATUS`).
       - 📷 Xanh mòng két: Thông báo biên bản bàn giao xe (`INSPECTION_UPDATE`).
       - 💵 Xanh lá: Thông báo thanh toán cọc thành công (`PAYMENT_UPDATE`).
     - Tiêu đề thông báo, nội dung chi tiết, thời gian.
     - Dấu chấm tròn biểu thị trạng thái chưa đọc.
  3. Khi người dùng nhấn vào thẻ thông báo: Gọi `NotificationService.markAsRead(id)` để đánh dấu đã đọc.

---

## 2. Các Service & Model Đã Có Sẵn Để Sử Dụng:
- **Service:**
  - `lib/data/services/gps_service.dart`: `pingGps()`, `getRenterFullRoute()`, `getOwnerSnapshot()`, `checkGpsStatus()`
  - `lib/data/services/notification_service.dart`: `getNotifications()`, `markAsRead()`
- **Model:**
  - `lib/data/models/gps_model.dart` (`GpsLogModel`, `GpsSnapshotModel`)
  - `lib/data/models/notification_model.dart`
- **Màu sắc & Style:** `lib/core/constants/app_colors.dart`
