# PHÂN HỆ: QUẢN LÝ XE CỦA CHỦ XE (VEHICLE MANAGEMENT)
**Người phụ trách:** 👤 **Thành viên 1**  
**Môn học:** PRM393 - Mobile Application Development (FPT University)

---

## 1. Danh Sách Màn Hình Cần Tạo (`lib/features/vehicle_management/screens/`):

### 1.1. `owner_vehicle_list_screen.dart` : Danh Sách Xe Của Tôi (Chủ xe)
- **Mục tiêu:** Giúp chủ xe xem và quản lý toàn bộ phương tiện của mình đang cho thuê trên hệ thống.
- **Thành phần giao diện:**
  1. AppBar: Tiêu đề *"Quản Lý Xe Của Tôi"*.
  2. Nút nổi FloatingActionButton (FAB): Icon `+` nhãn *"Đăng xe mới"* $\rightarrow$ Mở `AddVehicleScreen()`.
  3. Trạng thái tải: `CircularProgressIndicator` khi đang fetch API.
  4. Trạng thái rỗng: Icon xe xám kèm thông báo *"Bạn chưa đăng chiếc xe nào"*.
  5. Danh sách thẻ xe (`ListView.builder`):
     - Mỗi thẻ hiển thị:
       - Tên xe (VD: *VinFast VF8 Plus 2024*).
       - Biển số xe (VD: *30H-999.88*).
       - Giá thuê gốc/ngày (sử dụng `CurrencyFormatter.format(v.basePricePerDay)`).
       - Huy hiệu có tài xế: Nếu `v.hasDriverOption == true`, hiển thị text màu tím *"Có tài xế riêng (+X đ/ngày)"*, ngược lại *"Chỉ tự lái"*.
       - Badge trạng thái: Màu xanh lá nếu `AVAILABLE` (Xe rảnh), màu cam nếu `RENTED` (Đang cho thuê).
- **Gọi API:**
  - `VehicleService.getOwnerVehicles()`

---

### 1.2. `add_vehicle_screen.dart` : Màn Hình Đăng Xe Mới
- **Mục tiêu:** Chủ xe điền thông tin xe và cấu hình **Nghiệp vụ đặc thù 1 (Dịch vụ kèm tài xế)**.
- **Các trường nhập liệu (Form Fields):**
  1. `Tên xe` (VD: *Toyota Camry 2.5Q 2023*).
  2. `Biển số xe` (VD: *29A-123.45*).
  3. `Hãng xe` (VD: *Toyota, VinFast, Hyundai, Mazda, Honda*).
  4. `Loại xe` (Dropdown: `SEDAN`, `SUV`, `HATCHBACK`, `MPV`).
  5. `Hộp số` (Dropdown: `AUTOMATIC` - Tự động, `MANUAL` - Số sàn).
  6. `Loại nhiên liệu` (Dropdown: `GASOLINE` - Xăng, `DIESEL` - Dầu, `ELECTRIC` - Điện).
  7. `Giá thuê gốc / ngày` (Số nguyên, VNĐ, VD: *1.200.000*).
  8. **Cấu hình Nghiệp vụ đặc thù 1 (Dịch vụ kèm tài xế):**
     - **SwitchListTile: "Hỗ trợ dịch vụ kèm tài xế riêng"**:
       - Mặc định: Bật hoặc tắt.
     - **Ô nhập "Phụ phí tài xế / ngày (VNĐ)"**:
       - Chỉ hiển thị (hoặc chỉ cho phép nhập) khi Switch trên được BẬT.
       - VD: *500.000 VNĐ/ngày*.
  9. `URL ảnh xe` (Text nhập link ảnh đại diện hoặc chọn từ thư viện ảnh qua `ImagePicker`).
- **Hành động & Xử lý:**
  - Nút bấm *"ĐĂNG XE NGAY"*:
    - Kiểm tra validate hợp lệ.
    - Gọi hàm: `VehicleService.createVehicle(...)`.
    - Thành công: Hiển thị SnackBar xanh *"Đăng xe thành công!"*, `Navigator.pop(context, true)` để danh sách tự làm mới.
    - Thất bại: Hiển thị thông báo lỗi.

---

## 2. Các Service & Model Đã Có Sẵn Để Sử Dụng:
- **Service:** `lib/data/services/vehicle_service.dart`:
  - `VehicleService.getOwnerVehicles()`
  - `VehicleService.createVehicle(...)`
- **Model:** `lib/data/models/vehicle_model.dart`
- **Tiện ích định dạng tiền:** `lib/core/utils/currency_formatter.dart`
- **Màu sắc & Style:** `lib/core/constants/app_colors.dart`
