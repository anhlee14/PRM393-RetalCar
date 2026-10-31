# PHÂN HỆ: THẨM ĐỊNH TÌNH TRẠNG XE BEFORE / AFTER (VEHICLE INSPECTION)
**Người phụ trách:** 👤 **Thành viên 3**  
**Môn học:** PRM393 - Mobile Application Development (FPT University)  
**Kiến trúc:** Feature-First Clean Architecture

---

## 1. Danh Sách Màn Hình Cần Làm (`lib/features/inspection/screens/`):

### 1.1. `photo_inspection_screen.dart` : Màn Hình Chụp Ảnh Biên Bản Bàn Giao Xe
- **File:** `lib/features/inspection/screens/photo_inspection_screen.dart`
- **Mục tiêu:** Thực hiện **Nghiệp vụ đặc thù 3**, chụp và lưu vết hiện trạng xe tại 2 thời điểm: Nhận xe (`CHECK_IN`) và Trả xe (`CHECK_OUT`).
- **Thành phần giao diện (UI Components):**
  1. Header: Banner hướng dẫn quy trình kiểm tra xe, màu sắc phân biệt rõ ràng:
     - Xanh dương cho giai đoạn `CHECK_IN` (Lúc nhận xe ban đầu).
     - Cam cho giai đoạn `CHECK_OUT` (Lúc hoàn trả xe để đối chiếu).
  2. **Lưới 6 Ô Chụp Ảnh Tiêu Chuẩn (Grid 2 cột):**
     - Tích hợp `ImagePicker` mở Camera chụp trực tiếp hoặc chọn từ Thư viện:
       1. 📸 `1. Đầu xe (Front)`
       2. 📸 `2. Đuôi xe (Rear)`
       3. 📸 `3. Sườn trái xe (Left Side)`
       4. 📸 `4. Sườn phải xe (Right Side)`
       5. 📸 `5. Đồng hồ ODO (Công-tơ-mét)`
       6. 📸 `6. Vạch mức xăng / Pin (%)`
     - Mỗi ô khi chưa chụp: Hiển thị icon Camera nét đứt kèm nhãn góc chụp.
     - Khi đã chụp: Hiển thị ảnh xem trước + icon dấu tích xanh lá xác nhận.
  3. **Chỉ số Đồng hồ & Nhiên liệu:**
     - Ô nhập `Số km ODO thực tế`: `TextFormField` (Keyboard: number, VD: *15.200 km*).
     - Ô nhập `Mức xăng/Pin thực tế`: `TextFormField` (Keyboard: number, VD: *100%*).
  4. Ghi chú tình trạng xe: Ô nhập text đa dòng (VD: *"Có vết trầy nhẹ ở góc cản sau bên phụ từ trước, xe sạch sẽ"*).
  5. Nút bấm: *"GỬI BIÊN BẢN THẨM ĐỊNH"*:
     - Kiểm tra đã chụp đủ 6 góc ảnh.
     - Gọi `InspectionService.submitInspection(...)` (`POST /api/inspections`).
     - SnackBar xanh *"Gửi biên bản thẩm định thành công!"*, `Navigator.pop(context, true)`.

---

### 1.2. `comparison_screen.dart` : Màn Hình Đối Chiếu Ảnh Trước & Sau (Before - After Comparison)
- **File:** `lib/features/inspection/screens/comparison_screen.dart`
- **Mục tiêu:** Màn hình đinh của **Nghiệp vụ đặc thù 3** dùng để demo bảo vệ đồ án, minh chứng việc giải quyết triệt để tranh chấp hư hại xe khi trả.
- **Thành phần giao diện (UI Components):**
  1. Thẻ Tóm tắt Cuốc xe: Tên xe, biển số, mã đơn thuê `#BK-XXXX`.
  2. **Khung Số Liệu Chênh Lệch Tự Động:**
     - Quãng đường khách đã chạy: `+odoDifferenceKm km` (Tự động tính: $\text{ODO}_{\text{checkout}} - \text{ODO}_{\text{checkin}}$).
     - Mức tiêu hao nhiên liệu: `fuelDifferencePercent %` (Tự động tính: $\text{Xăng}_{\text{checkout}} - \text{Xăng}_{\text{checkin}}$).
  3. **Giao Diện So Sánh Trực Quan 6 Cặp Ảnh (Side-by-Side):**
     - Đặt ảnh **Lúc nhận (Check-in)** và ảnh **Lúc trả (Check-out)** cạnh nhau theo từng cặp:
       - Cặp 1: Đầu xe Trước vs Sau
       - Cặp 2: Đuôi xe Trước vs Sau
       - Cặp 3: Sườn trái Trước vs Sau
       - Cặp 4: Sườn phải Trước vs Sau
       - Cặp 5: ODO km Lúc nhận vs Lúc trả
       - Cặp 6: Xăng % Lúc nhận vs Lúc trả
  4. **Thanh Trạng Thái Đồng Thuận 2 Bên (Mutual Sign-off):**
     - Khách thuê đã ký xác nhận: ✅ / ⏳
     - Chủ xe đã ký xác nhận: ✅ / ⏳
     - Nếu cả 2 bên cùng xác nhận: Khung xanh lá *"Hai bên đã ký biên bản bàn giao thành công! Thủ tục hoàn cọc hoàn tất."*
  5. Nút bấm: *"XÁC NHẬN BÀN GIAO & HOÀN CỌC"*:
     - Gọi `InspectionService.confirmInspection(inspectionId)` (`PUT /api/inspections/{id}/confirm`).
     - Tự động làm mới giao diện và hiển thị trạng thái đã hoàn tất.

---

## 2. Hướng Dẫn Gọi API & Kết Nối Dữ Liệu:

```dart
// 1. Gửi biên bản ảnh nhận hoặc trả xe:
final result = await InspectionService.submitInspection(
  bookingId: bookingId,
  stage: 'CHECK_IN', // hoặc 'CHECK_OUT'
  frontImg: frontUrl,
  rearImg: rearUrl,
  leftImg: leftUrl,
  rightImg: rightUrl,
  odoImg: odoUrl,
  fuelImg: fuelUrl,
  odoKm: 15200.0,
  fuelLevelPercent: 100.0,
  notes: 'Xe sạch sẽ...',
);

// 2. Lấy dữ liệu đối chiếu Before/After:
InspectionComparisonModel? comp = await InspectionService.getComparison(bookingId);

// 3. Ký xác nhận đồng thuận hoàn cọc:
bool confirmed = await InspectionService.confirmInspection(inspectionId);
```

---

## 3. Các File Đã Có Sẵn Trong Dự Án Để Dùng Ngay:
- Service: `lib/data/services/inspection_service.dart`
- Model: `lib/data/models/inspection_model.dart`
- Package mở Camera/Thư viện: `image_picker: ^1.1.2` (đã cài sẵn trong `pubspec.yaml`)
- Màu sắc: `lib/core/constants/app_colors.dart`
