# PHÂN HỆ: KHÁM PHÁ & THUẬT TOÁN MATCHING % (MATCHING & EXPLORE)
**Người phụ trách:** 👤 **Thành viên 2**  
**Môn học:** PRM393 - Mobile Application Development (FPT University)

---

## 1. Danh Sách Màn Hình Cần Tạo (`lib/features/matching_explore/`):

### 1.1. `screens/explore_screen.dart` : Trang Khám Phá Xe & Điểm % Matching Thông Minh
- **Mục tiêu:** Màn hình chính của khách thuê xe, hiển thị danh sách xe đề xuất theo **Nghiệp vụ đặc thù 4 (Smart Matching Engine)**.
- **Thành phần giao diện:**
  1. Header: Ô tìm kiếm từ khóa tên xe + Nút Icon bộ lọc (Filter Icon) để mở `MatchingFilterSheet`.
  2. Banner nổi bật: Giới thiệu thuật toán khớp xe thông minh theo vị trí GPS, giá cả và nhu cầu có lái xe.
  3. Danh sách thẻ xe dạng dọc hoặc lưới 2 cột:
     - Hình ảnh xe (kèm hiệu ứng bo góc).
     - **Huy hiệu Điểm % Khớp Thông Minh (Match Score Badge - Nghiệp vụ 4):**
       - Hiển thị nổi bật ở góc trên ảnh: `98% MATCH` (màu xanh lá nếu > 80%, màu vàng cam nếu 50-80%, màu xám nếu < 50%).
     - Tên xe và Hãng sản xuất.
     - Giá thuê gốc: `X đ/ngày` (sử dụng `CurrencyFormatter.format(v.basePricePerDay)`).
     - Huy hiệu có tài xế: Thẻ nhỏ *"Có tài xế"* nếu xe hỗ trợ.
     - Vị trí xe & Khoảng cách tính từ vị trí người dùng (VD: *Cách bạn 2.5 km*).
  4. Bấm vào thẻ xe: Điều hướng sang `VehicleDetailScreen(vehicle: v)`.
- **Gọi API:**
  - `VehicleService.searchMatchingVehicles(...)`

---

### 1.2. `widgets/matching_filter_sheet.dart` : Bộ Lọc Matching Thông Minh (Thanh Trượt Sliders)
- **Mục tiêu:** Cho phép người dùng tuỳ chỉnh trọng số thuật toán Matching để Backend tính lại điểm % khớp trong thời gian thực.
- **Thành phần giao diện (Hiển thị dạng `showModalBottomSheet`):**
  1. Tiêu đề: *"Cấu hình Tìm kiếm Thông minh (Matching Sliders)"*.
  2. **Thanh trượt Trọng số Giá cả (`priceWeight`):** Slider từ 0.0 đến 1.0 (Ưu tiên xe tiết kiệm ngân sách).
  3. **Thanh trượt Trọng số Vị trí gần (`distanceWeight`):** Slider từ 0.0 đến 1.0 (Ưu tiên xe gần toạ độ hiện tại của tôi).
  4. **Thanh trượt Ngân sách tối đa (`maxBudget`):** Slider từ 500.000 đ đến 5.000.000 đ/ngày.
  5. **Tuỳ chọn Lái xe (`requireDriver`):** Checkbox hoặc Switch: *"Bắt buộc xe phải có tài xế"*.
  6. **Lựa chọn Hộp số & Loại xe:** ChoiceChips (`AUTOMATIC` / `MANUAL`, `SEDAN` / `SUV`...).
  7. Nút bấm: *"ÁP DỤNG BỘ LỌC"* $\rightarrow$ Gửi các tham số này vào `VehicleService.searchMatchingVehicles` để reload lại danh sách xe kèm điểm % mới.

---

### 1.3. `screens/vehicle_detail_screen.dart` : Màn Hình Chi Tiết Xe
- **Mục tiêu:** Hiển thị thông số kỹ thuật đầy đủ của xe, bảng giá và nút điều hướng đến màn hình Đặt xe.
- **Thành phần giao diện:**
  1. Carousel ảnh xe lớn (kèm chỉ số trang `1/3`).
  2. Tên xe, biển số, năm sản xuất, đánh giá sao (⭐️ 4.9/5.0).
  3. Bảng thông số: Hộp số, Nhiên liệu, Số chỗ ngồi, Mức tiêu hao nhiên liệu.
  4. **Khung Bảng Giá Minh Bạch (Nghiệp vụ 1):**
     - Giá thuê tự lái: `v.basePricePerDay` đ/ngày.
     - Phụ phí tài xế riêng (nếu có): `+v.driverFeePerDay` đ/ngày.
  5. Thông tin chủ xe (Avatar, tên, số điện thoại liên hệ).
  6. Thanh dưới cùng (Bottom Bar):
     - Giá hiển thị: `X đ/ngày`.
     - Nút bấm *"ĐẶT XE NGAY"*: Điều hướng sang `BookingFormScreen(vehicle: v)`.

---

## 2. Các Service & Model Đã Có Sẵn Để Sử Dụng:
- **Service:** `lib/data/services/vehicle_service.dart`:
  - `VehicleService.getAllVehicles()`
  - `VehicleService.searchMatchingVehicles(...)`
- **Model:** `lib/data/models/vehicle_model.dart`
- **Tiện ích:** `lib/core/utils/currency_formatter.dart`
- **Màu sắc & Style:** `lib/core/constants/app_colors.dart`
