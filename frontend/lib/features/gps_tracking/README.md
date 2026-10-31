# PHÂN HỆ: ĐỊNH VỊ GPS, BẢO VỆ RIÊNG TƯ & THÔNG BÁO (GPS & PRIVACY)
**Người phụ trách:** 👤 **Thành viên 3**  
**Môn học:** PRM393 - Mobile Application Development (FPT University)  
**Kiến trúc:** Feature-First Clean Architecture

---

## 1. Danh Sách Màn Hình Cần Làm (`lib/features/gps_tracking/screens/`):

### 1.1. `renter_route_map_screen.dart` : Bản Đồ Lộ Trình Của Khách Thuê
- **File:** `lib/features/gps_tracking/screens/renter_route_map_screen.dart`
- **Mục tiêu:** Thực hiện **Nghiệp vụ đặc thù 2**, cho phép khách thuê xem toàn bộ lịch sử di chuyển và tuân thủ quy định gửi toạ độ tối đa 60 phút/lần.
- **Thành phần giao diện (UI Components):**
  1. **Banner Cảnh Báo Quy Định 1 Tiếng (Quy định an toàn hợp đồng):**
     - Gọi `GpsService.checkGpsStatus(bookingId)`.
     - Nếu `is_overdue == true` (đã quá 60 phút chưa gửi toạ độ GPS):
       - Khung viền màu đỏ rực kèm icon cảnh báo: *"⚠️ CẢNH BÁO: Đã X phút bạn chưa cập nhật toạ độ GPS. Vui lòng gửi vị trí ngay để tránh bị phạt vi phạm hợp đồng!"*.
     - Nếu bình thường: Khung xanh lá *"✅ Tình trạng GPS hợp lệ. Lần gửi gần nhất: X phút trước"*.
  2. **Khung Bản Đồ Lộ Trình Đầy Đủ (Full Route Visualization):**
     - Hiển thị danh sách các toạ độ xe đã đi qua.
     - Đường nét vẽ lộ trình di chuyển (Polyline).
     - Huy hiệu góc: *"Quyền riêng tư: Chỉ khách thuê mới xem được toàn bộ lộ trình này"*.
  3. **Nút Nổi (FAB): "GỬI VỊ TRÍ HIỆN TẠI (PING GPS)":**
     - Khi bấm: Lấy toạ độ thiết bị và gọi `GpsService.pingGps(bookingId, latitude, longitude, speed)`.
     - Tự động reset lại bộ đếm giờ 60 phút về 0 và cập nhật mốc toạ độ mới lên bản đồ.
  4. Lịch sử các mốc toạ độ (`ListView`): Hiển thị toạ độ (Kinh độ, Vĩ độ), tốc độ (km/h) và thời gian ghi nhận.

---

### 1.2. `owner_snapshot_screen.dart` : Bản Đồ Hiện Trạng Xe Của Chủ Xe (Bảo Vệ Quyền Riêng Tư)
- **File:** `lib/features/gps_tracking/screens/owner_snapshot_screen.dart`
- **Mục tiêu:** Thực hiện **Nghiệp vụ đặc thù 2 (Chính sách riêng tư chuẩn GDPR)**, bảo đảm chủ xe không theo dõi lén khách thuê.
- **Quy tắc bảo mật bắt buộc:**
  - **TUYỆT ĐỐI KHÔNG HIỂN THỊ ĐƯỜNG ĐI (NO ROUTE / NO POLYLINE).**
  - Chỉ hiển thị duy nhất **1 Marker vị trí tức thời (Snapshot)** của xe tại thời điểm kiểm tra.
- **Thành phần giao diện (UI Components):**
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
- **File:** `lib/features/gps_tracking/screens/notifications_screen.dart`
- **Mục tiêu:** Tiếp nhận và hiển thị các cảnh báo tự động từ hệ thống và tiến trình nền Scheduler.
- **Thành phần giao diện (UI Components):**
  1. AppBar: *"Thông Báo Hệ Thống"*, nút Tải lại.
  2. Danh sách thông báo dạng thẻ bo góc (`ListView.separated`):
     - Icon và màu sắc phân loại:
       - 🚨 Đỏ: Cảnh báo quá 1 tiếng chưa bật GPS (`GPS_WARNING`).
       - 📝 Xanh dương: Thông báo duyệt đơn đặt xe (`BOOKING_STATUS`).
       - 📷 Xanh mòng két: Thông báo biên bản bàn giao xe (`INSPECTION_UPDATE`).
       - 💵 Xanh lá: Thông báo thanh toán cọc thành công (`PAYMENT_UPDATE`).
     - Tiêu đề thông báo, nội dung chi tiết, thời gian.
     - Dấu chấm tròn biểu thị trạng thái chưa đọc.
  3. Khi người dùng nhấn vào thẻ thông báo: Gọi `NotificationService.markAsRead(id)` để đánh dấu đã đọc.

---

## 2. Hướng Dẫn Gọi API & Kết Nối Dữ Liệu:

```dart
// 1. Khách gửi toạ độ GPS:
bool ok = await GpsService.pingGps(
  bookingId: bookingId,
  latitude: 21.0285,
  longitude: 105.8542,
  speed: 45.0,
);

// 2. Khách xem toàn bộ lộ trình:
List<GpsLogModel> route = await GpsService.getRenterFullRoute(bookingId);

// 3. Khách kiểm tra cảnh báo quá 1h:
Map<String, dynamic> status = await GpsService.checkGpsStatus(bookingId);
bool isOverdue = status['is_overdue'] == true;

// 4. Chủ xe xem Snapshot 1 điểm và Quota:
final res = await GpsService.getOwnerSnapshot(bookingId);
if (res['success'] == true) {
  GpsSnapshotModel snap = res['data'];
  print('Lượt còn lại: ${snap.remainingChecksToday}/20');
}

// 5. Lấy danh sách thông báo:
List<NotificationModel> notis = await NotificationService.getNotifications();
```

---

## 3. Các File Đã Có Sẵn Trong Dự Án Để Dùng Ngay:
- Service: `lib/data/services/gps_service.dart` và `lib/data/services/notification_service.dart`
- Model: `lib/data/models/gps_model.dart` và `lib/data/models/notification_model.dart`
- Màu sắc: `lib/core/constants/app_colors.dart`
