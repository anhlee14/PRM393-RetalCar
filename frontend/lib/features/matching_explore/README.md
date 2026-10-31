# PHÂN HỆ: KHÁM PHÁ & THUẬT TOÁN MATCHING % (MATCHING & EXPLORE)
**Người phụ trách:** 👤 **Thành viên 2**  
**Môn học:** PRM393 - Mobile Application Development (FPT University)  
**Kiến trúc:** Feature-First Clean Architecture

---

## 1. Danh Sách Màn Hình Cần Làm (`lib/features/matching_explore/`):

### 1.1. `screens/explore_screen.dart` : Trang Khám Phá Xe & Điểm % Matching Thông Minh
- **File:** `lib/features/matching_explore/screens/explore_screen.dart`
- **Mục tiêu:** Màn hình chính của khách thuê xe (Tab 1), hiển thị danh sách các xe kèm **Huy hiệu điểm tương thích % (Nghiệp vụ đặc thù 4)**.
- **Thành phần giao diện (UI Components):**
  1. Header Search Bar:
     - Ô tìm kiếm text theo tên xe hoặc hãng xe.
     - Nút icon Lọc (Filter Icon) để mở `MatchingFilterSheet`.
  2. Banner thuật toán thông minh:
     - Khung thông báo: *"Hệ thống tự động chấm điểm % phù hợp dựa trên vị trí GPS, ngân sách và nhu cầu tài xế của bạn"*.
  3. Danh sách thẻ xe (`ListView.builder`):
     - Mỗi thẻ xe gồm:
       - Ảnh lớn của xe (kèm bo góc).
       - **Huy hiệu Tỉ lệ khớp % (Match Score Badge - Nghiệp vụ 4):**
         - Nằm ở góc trên cùng bên phải ảnh:
           - Màu xanh lá đậm: `98% MATCH` (nếu điểm > 80% - Rất phù hợp).
           - Màu cam vàng: `72% MATCH` (nếu điểm 50% - 80% - Phù hợp).
           - Màu xám: `45% MATCH` (nếu điểm < 50% - Ít phù hợp).
       - Tên xe và Hãng sản xuất (VD: *VinFast VF8 Plus*).
       - Thông số nhanh: Hộp số tự động, 5 chỗ, Nhiên liệu điện.
       - Khoảng cách GPS tính từ vị trí người dùng (VD: *Cách bạn 2.3 km*).
       - Giá thuê gốc: `X đ/ngày` (sử dụng `CurrencyFormatter.format(v.basePricePerDay)`).
       - Thẻ nhỏ: *"🚗 Có tài xế riêng"* nếu `v.hasDriverOption == true`.
  4. Bấm vào thẻ xe: Điều hướng sang `VehicleDetailScreen(vehicle: v)`.
- **Gọi API:**
  - `VehicleService.searchMatchingVehicles(...)` (`POST /api/vehicles/match` hoặc `POST /api/matching/search`).

---

### 1.2. `widgets/matching_filter_sheet.dart` : Bộ Lọc Matching Thông Minh (Thanh Trượt Sliders)
- **File:** `lib/features/matching_explore/widgets/matching_filter_sheet.dart`
- **Mục tiêu:** Hiển thị dạng `showModalBottomSheet`, cho phép người dùng kéo các thanh trượt trọng số để Backend tính toán lại điểm % khớp trong thời gian thực.
- **Thành phần giao diện (UI Components):**
  1. Tiêu đề: *"Cấu hình Tìm kiếm Thông minh (Matching Sliders)"*.
  2. **Thanh trượt Trọng số Giá cả (`budgetWeight`):**
     - `Slider`: Giá trị từ `0.0` đến `1.0` (Ưu tiên xe giá rẻ, tiết kiệm chi phí).
  3. **Thanh trượt Trọng số Khoảng cách gần (`distanceWeight`):**
     - `Slider`: Giá trị từ `0.0` đến `1.0` (Ưu tiên xe ở gần toạ độ hiện tại của tôi nhất).
  4. **Thanh trượt Ngân sách tối đa (`budget`):**
     - `Slider`: Từ 500.000 đ đến 5.000.000 đ/ngày.
  5. **Tuỳ chọn Tài xế riêng (`needDriver`):**
     - `SwitchListTile`: *"Bắt buộc xe phải có tuỳ chọn kèm tài xế"*.
  6. **Lựa chọn Loại xe & Hộp số:**
     - `FilterChip`: `SEDAN`, `SUV`, `MPV`, `HATCHBACK`.
     - `FilterChip`: `Số tự động`, `Số sàn`.
  7. Nút bấm: *"ÁP DỤNG BỘ LỌC"*:
     - Gom toàn bộ tham số gửi vào hàm `VehicleService.searchMatchingVehicles(...)`.
     - Đóng BottomSheet và cập nhật danh sách xe với điểm % mới.

---

### 1.3. `screens/vehicle_detail_screen.dart` : Màn Hình Chi Tiết Xe
- **File:** `lib/features/matching_explore/screens/vehicle_detail_screen.dart`
- **Mục tiêu:** Hiển thị đầy đủ thông số kỹ thuật, bộ sưu tập ảnh và bảng giá minh bạch trước khi khách đặt xe.
- **Thành phần giao diện (UI Components):**
  1. Carousel ảnh xe lớn (kèm chỉ số trang `1/3`).
  2. Tên xe, Biển số, Hãng sản xuất, Đánh giá sao (⭐️ 5.0/5.0).
  3. Lưới thông số kỹ thuật (Grid 4 ô): Hộp số, Nhiên liệu, Số ghế ngồi, Năm sản xuất.
  4. Vị trí xe & Bản đồ thu nhỏ địa chỉ nhận xe.
  5. **Khung Bảng Giá Minh Bạch (Nghiệp vụ đặc thù 1):**
     - Giá thuê tự lái: `v.basePricePerDay` đ/ngày.
     - Phụ phí tài xế riêng (nếu có): `+v.driverFeePerDay` đ/ngày.
  6. Thông tin Chủ xe: Avatar, Tên chủ xe, Số điện thoại liên hệ.
  7. Thanh điều hướng dưới cùng (Bottom Bar):
     - Hiển thị giá: `X đ/ngày`.
     - Nút bấm *"ĐẶT XE NGAY"*: Điều hướng sang `BookingFormScreen(vehicle: v)`.

---

## 2. Hướng Dẫn Gọi API & Kết Nối Dữ Liệu:

```dart
// 1. Gọi thuật toán Matching Engine:
final matchingVehicles = await VehicleService.searchMatchingVehicles(
  budget: 1500000,
  needDriver: true,
  userLat: 21.0131,
  userLng: 105.5255,
  budgetWeight: 0.3,
  distanceWeight: 0.3,
  driverWeight: 0.2,
);

// 2. Lấy chi tiết xe:
final vehicle = await VehicleService.getVehicleById(vehicleId);
```

---

## 3. Các File Đã Có Sẵn Trong Dự Án Để Dùng Ngay:
- Service: `lib/data/services/vehicle_service.dart`
- Model: `lib/data/models/vehicle_model.dart`
- Tiện ích định dạng tiền: `lib/core/utils/currency_formatter.dart`
- Màu sắc: `lib/core/constants/app_colors.dart`
