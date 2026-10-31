# PHÂN HỆ: THẨM ĐỊNH TÌNH TRẠNG XE BEFORE / AFTER (VEHICLE INSPECTION)
**Người phụ trách:** 👤 **Thành viên 3**  
**Môn học:** PRM393 - Mobile Application Development (FPT University)

---

## 1. Danh Sách Màn Hình Cần Tạo (`lib/features/inspection/screens/`):

### 1.1. `photo_inspection_screen.dart` : Màn Hình Chụp Ảnh Biên Bản Bàn Giao Xe
- **Mục tiêu:** Thực hiện **Nghiệp vụ đặc thù 3**, chụp và lưu vết hiện trạng xe tại 2 thời điểm: Nhận xe (`CHECK_IN`) và Trả xe (`CHECK_OUT`).
- **Thành phần giao diện:**
  1. Header: Banner hướng dẫn quy trình kiểm tra xe, màu sắc phân biệt rõ ràng:
     - Xanh dương cho `CHECK_IN` (Lúc nhận xe).
     - Cam cho `CHECK_OUT` (Lúc trả xe).
  2. **Lưới 6 Ô Chụp Ảnh Tiêu Chuẩn (Grid 2 cột):**
     - Tích hợp `ImagePicker` mở Camera chụp trực tiếp hoặc chọn từ Thư viện:
       1. 📸 `Đầu xe (Front)`
       2. 📸 `Đuôi xe (Rear)`
       3. 📸 `Sườn trái xe (Left Side)`
       4. 📸 `Sườn phải xe (Right Side)`
       5. 📸 `Đồng hồ ODO (Công-tơ-mét)`
       6. 📸 `Vạch mức xăng / Pin (%)`
     - Mỗi ô khi chưa chụp hiển thị icon Camera nét đứt; khi đã chụp hiển thị ảnh xem trước + icon dấu tích xanh lá.
  3. **Chỉ số Đồng hồ & Nhiên liệu:**
     - Ô nhập `Số km ODO thực tế` (Number, VD: *15.200 km*).
     - Ô nhập `Mức xăng/Pin thực tế` (Number, VD: *100%*).
  4. Ghi chú tình trạng xe: Ô nhập text đa dòng (VD: *"Có vết xước nhỏ ở cản sau từ trước, xe sạch sẽ"*).
  5. Nút bấm: *"GỬI BIÊN BẢN THẨM ĐỊNH"*:
     - Kiểm tra đủ ảnh hoặc cảnh báo nếu chưa đủ.
     - Gọi `InspectionService.submitInspection(...)`.
     - Thành công: SnackBar thông báo thành công và `pop` màn hình.

---

### 1.2. `comparison_screen.dart` : Màn Hình Đối Chiếu Ảnh Trước & Sau (Before - After Comparison)
- **Mục tiêu:** Màn hình đinh của **Nghiệp vụ đặc thù 3** dùng để demo bảo vệ đồ án, minh chứng việc giải quyết triệt để tranh chấp hư hại xe.
- **Thành phần giao diện:**
  1. Thẻ Tóm tắt Chuyến đi: Tên xe, biển số, mã đơn thuê.
  2. **Khung Số Liệu Chênh Lệch Tự Động:**
     - Quãng đường khách đã chạy: `+odoDifferenceKm km` (Tự động tính: $\text{ODO}_{\text{checkout}} - \text{ODO}_{\text{checkin}}$).
     - Mức tiêu hao nhiên liệu: `fuelDifferencePercent %` (Tự động tính: $\text{Xăng}_{\text{checkout}} - \text{Xăng}_{\text{checkin}}$).
  3. **Giao Diện So Sánh Trực Quan 6 Góc Ảnh (Side-by-Side):**
     - Đặt ảnh **Lúc nhận (Check-in)** và ảnh **Lúc trả (Check-out)** cạnh nhau theo cặp:
       - Cặp 1: Đầu xe Trước vs Sau
       - Cặp 2: Đuôi xe Trước vs Sau
       - Cặp 3: Sườn trái Trước vs Sau
       - Cặp 4: Sườn phải Trước vs Sau
       - Cặp 5: ODO Lúc nhận vs ODO Lúc trả
       - Cặp 6: Xăng Lúc nhận vs Xăng Lúc trả
  4. **Thanh Trạng Thái Đồng Thuận 2 Bên (Mutual Sign-off):**
     - Khách thuê đã ký xác nhận: ✅ / ⏳
     - Chủ xe đã ký xác nhận: ✅ / ⏳
     - Nếu cả 2 bên cùng xác nhận: Hiện khung xanh lá *"Hai bên đã ký biên bản bàn giao thành công! Hoàn trả tiền cọc hoàn tất."*
  5. Nút bấm: *"XÁC NHẬN BÀN GIAO & HOÀN CỌC"*:
     - Gọi `InspectionService.confirmInspection(inspectionId)`.
     - Reload lại dữ liệu để cập nhật trạng thái đồng thuận.

---

## 2. Các Service & Model Đã Có Sẵn Để Sử Dụng:
- **Service:** `lib/data/services/inspection_service.dart`:
  - `submitInspection(...)`
  - `getComparison(bookingId)`
  - `confirmInspection(id)`
- **Model:** `lib/data/models/inspection_model.dart` (`InspectionModel`, `InspectionComparisonModel`)
- **Package ảnh:** `image_picker: ^1.1.2` (đã cài trong `pubspec.yaml`)
- **Màu sắc & Style:** `lib/core/constants/app_colors.dart`
