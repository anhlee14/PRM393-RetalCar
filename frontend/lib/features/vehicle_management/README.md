# PHÂN HỆ: QUẢN LÝ XE CỦA CHỦ XE (VEHICLE MANAGEMENT)
**Người phụ trách:** 👤 **Thành viên 1**  
**Môn học:** PRM393 - Mobile Application Development (FPT University)  
**Kiến trúc:** Feature-First Clean Architecture

---

## 1. Danh Sách Màn Hình Cần Làm (`lib/features/vehicle_management/screens/`):

### 1.1. `owner_vehicle_list_screen.dart` : Danh Sách Xe Cho Thuê Của Tôi
- **File:** `lib/features/vehicle_management/screens/owner_vehicle_list_screen.dart`
- **Mục tiêu:** Màn hình chính trong Tab Chủ xe, hiển thị toàn bộ phương tiện thuộc sở hữu của chủ xe, tình trạng hoạt động và menu thao tác nhanh.
- **Thành phần giao diện (UI Components):**
  1. AppBar: Tiêu đề *"Xe Cho Thuê Của Tôi"*, nút icon Refresh.
  2. Nút nổi FloatingActionButton (FAB): Icon `+` nhãn *"Đăng xe mới"* $\rightarrow$ Mở `AddVehicleScreen()`.
  3. Trạng thái rỗng: Icon xe xám kèm text *"Bạn chưa đăng tải chiếc xe nào. Hãy nhấn Đăng xe mới để bắt đầu kiếm thu nhập!"*.
  4. Danh sách thẻ xe (`ListView.builder`):
     - Mỗi xe là 1 `Card` bo góc sang trọng gồm:
       - Ảnh đại diện xe (Thumbnail bo góc).
       - Tên xe (VD: *VinFast VF8 Plus 2024*).
       - Biển số xe: Khung viền nhỏ viền đen chữ đậm (VD: `30K-888.88`).
       - Giá thuê tự lái: `X đ/ngày` (sử dụng `CurrencyFormatter.format(v.basePricePerDay)`).
       - **Huy hiệu Có Tài Xế (Nghiệp vụ đặc thù 1):**
         - Nếu `hasDriverOption == true`: Thẻ tím nhỏ *"🚗 Có tài xế (+X đ/ngày)"*.
         - Nếu `false`: Thẻ xám *"🚙 Chỉ tự lái"*.
       - Chip trạng thái:
         - Màu xanh lá: `AVAILABLE` (Sẵn sàng đón khách).
         - Màu cam: `RENTED` / `ONGOING` (Đang có khách thuê).
         - Màu xám: `MAINTENANCE` (Đang bảo dưỡng).
     - **Thanh nút tác vụ nhanh (Action Buttons):**
       - Nút *"Chỉnh sửa"* (Icon bút chì): Điều hướng sang `EditVehicleScreen(vehicle: v)`.
       - Nút *"Xem vị trí GPS"* (Icon radar/vị trí): Mở `OwnerSnapshotScreen(bookingId: ..., vehicleName: v.name)` để kiểm tra toạ độ tức thời của xe (tính vào quota 20 lượt/ngày).
- **Gọi API:**
  - `VehicleService.getOwnerVehicles()`

---

### 1.2. `add_vehicle_screen.dart` : Form Đăng Xe Mới
- **File:** `lib/features/vehicle_management/screens/add_vehicle_screen.dart`
- **Mục tiêu:** Chủ xe điền thông số xe và cấu hình **Nghiệp vụ đặc thù 1 (Dịch vụ thuê xe kèm tài xế)**.
- **Thành phần giao diện (UI Components):**
  1. Khung chọn ảnh xe:
     - Ô chọn ảnh đại diện xe từ Camera hoặc Thư viện ảnh (`ImagePicker`).
     - Tự động gọi API `POST /api/upload` để lấy URL ảnh tĩnh từ server.
  2. Thông tin cơ bản của xe:
     - `Tên xe`: `TextFormField` (VD: *Toyota Fortuner Legender 2023*).
     - `Biển số xe`: `TextFormField` (VD: *29A-999.88*).
     - `Hãng sản xuất`: `DropdownButtonFormField` (*Toyota, VinFast, Hyundai, Mazda, Honda, Kia, Ford*).
     - `Năm sản xuất`: `TextFormField` (VD: *2023*).
     - `Loại xe`: `DropdownButtonFormField` (`SEDAN`, `SUV`, `MPV`, `HATCHBACK`, `PICKUP`).
     - `Hộp số`: `DropdownButtonFormField` (`AUTOMATIC` - Tự động, `MANUAL` - Số sàn).
     - `Loại nhiên liệu`: `DropdownButtonFormField` (`GASOLINE` - Xăng, `DIESEL` - Dầu, `ELECTRIC` - Điện, `HYBRID` - Lai điện).
     - `Số chỗ ngồi`: `DropdownButtonFormField` (4 chỗ, 5 chỗ, 7 chỗ).
     - `Địa chỉ nhận xe`: `TextFormField` (VD: *Khu CNC Hòa Lạc, Thạch Thất, Hà Nội*).
     - `Giá thuê tự lái / ngày`: `TextFormField` (Số nguyên VNĐ, VD: *1.200.000*).
  3. **Cấu hình Nghiệp vụ đặc thù 1 (Dịch vụ kèm tài xế riêng):**
     - **SwitchListTile: "Hỗ trợ dịch vụ kèm tài xế riêng"**:
       - Bật/Tắt tuỳ chọn.
     - **Ô nhập: "Phụ phí tài xế riêng / ngày (VNĐ)"**:
       - Tự động mở khi Switch được bật (VD: *450.000 đ/ngày*).
       - Bị vô hiệu hoá và đặt về 0 khi Switch tắt.
  4. Nút bấm *"ĐĂNG XE NGAY"*:
     - Kiểm tra validate hợp lệ.
     - Gọi `VehicleService.createVehicle(...)` (`POST /api/vehicles`).
     - SnackBar xanh *"Đăng xe thành công!"*, `Navigator.pop(context, true)`.

---

### 1.3. `edit_vehicle_screen.dart` : Form Chỉnh Sửa & Xóa Xe
- **File:** `lib/features/vehicle_management/screens/edit_vehicle_screen.dart`
- **Mục tiêu:** Cho phép chủ xe cập nhật thông tin xe (`PUT /api/vehicles/{id}`) hoặc xóa hẳn xe (`DELETE /api/vehicles/{id}`).
- **Thành phần giao diện (UI Components):**
  1. Hiển thị sẵn các thông tin cũ của xe vào các ô Form (Tên, giá thuê, phụ phí tài xế, địa chỉ...).
  2. Nút *"LƯU THAY ĐỔI"*:
     - Gọi API: `PUT /api/vehicles/{id}`.
     - SnackBar xanh *"Cập nhật thông tin xe thành công!"*, pop về danh sách xe.
  3. Nút *"XÓA BỎ CHIẾC XE NÀY"* (Nút màu đỏ):
     - Hiển thị `AlertDialog` cảnh báo: *"Bạn có chắc chắn muốn xóa chiếc xe này không? Hành động này không thể hoàn tác!"*.
     - Bấm Xác nhận: Gọi API `DELETE /api/vehicles/{id}`.
     - **Cơ chế an toàn:** Nếu Backend trả về lỗi (do xe đang có khách thuê hoạt động `ONGOING`), hiển thị SnackBar đỏ: *"Không thể xóa xe vì xe đang có chuyến đi hoạt động!"*.

---

## 2. Hướng Dẫn Gọi API & Kết Nối Dữ Liệu:

```dart
// 1. Lấy danh sách xe của chủ xe:
List<VehicleModel> vehicles = await VehicleService.getOwnerVehicles();

// 2. Đăng xe mới (kèm phụ phí tài xế):
final result = await VehicleService.createVehicle(
  name: name,
  brand: brand,
  licensePlate: licensePlate,
  basePricePerDay: basePrice,
  hasDriverOption: hasDriver,
  driverFeePerDay: driverFee,
  address: address,
);

// 3. Sửa thông tin xe:
final res = await ApiClient.put('/api/vehicles/${vehicle.id}', body: updatedData);

// 4. Xóa hẳn xe:
final res = await ApiClient.delete('/api/vehicles/${vehicle.id}');
```

---

## 3. Các File Đã Có Sẵn Trong Dự Án Để Dùng Ngay:
- Service: `lib/data/services/vehicle_service.dart`
- Model: `lib/data/models/vehicle_model.dart`
- Network: `lib/core/network/api_client.dart`
- Tiện ích định dạng tiền VNĐ: `lib/core/utils/currency_formatter.dart`
- Màu sắc: `lib/core/constants/app_colors.dart`
