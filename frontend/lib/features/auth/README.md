# PHÂN HỆ: XÁC THỰC & HỒ SƠ NGƯỜI DÙNG (AUTH & PROFILE)
**Người phụ trách:** 👤 **Thành viên 1**  
**Môn học:** PRM393 - Mobile Application Development (FPT University)

---

## 1. Danh Sách Màn Hình Cần Tạo (`lib/features/auth/screens/`):

### 1.1. `login_screen.dart` (ĐÃ HOÀN THIỆN - ĐỂ NGUYÊN)
- Đã được xây dựng sẵn để làm mẫu chuẩn kết nối `AuthService.login(email, password)`.
- Lưu JWT token vào `SharedPreferences` thông qua `ApiClient`.

---

### 1.2. `register_screen.dart` : Màn hình Đăng Ký Tài Khoản Mới
- **Mục tiêu:** Cho phép người dùng đăng ký tài khoản Khách thuê hoặc Chủ xe.
- **Các trường nhập liệu (Form Fields):**
  1. `Họ và tên` (Text, Validate: không để trống).
  2. `Email` (EmailAddress, Validate: đúng định dạng email).
  3. `Mật khẩu` (Password, ẩn/hiện mắt xem, tối thiểu 6 ký tự).
  4. `Số điện thoại` (Phone, 10 số).
  5. `Số CCCD / CMND` (Text, 12 số, căn cước công dân).
  6. `Số Giấy phép lái xe (GPLX)` (Text, số bằng lái xe B1/B2).
  7. `Lựa chọn vai trò ban đầu` (Radio Button hoặc ChoiceChip: `Khách thuê xe (RENTER)` hoặc `Chủ xe (OWNER)`).
- **Hành động & Xử lý:**
  - Nút bấm *"ĐĂNG KÝ TÀI KHOẢN"*:
    - Kiểm tra `FormKey.currentState.validate()`.
    - Gọi hàm: `AuthService.register(fullName, email, password, phone, role, cccdNumber, driverLicense)`.
    - Thành công: Hiển thị SnackBar màu xanh *"Đăng ký thành công! Vui lòng đăng nhập"*, điều hướng quay lại `LoginScreen`.
    - Thất bại: Hiển thị SnackBar màu đỏ kèm thông báo lỗi từ Backend.
  - Nút *"Đã có tài khoản? Đăng nhập ngay"*: Pop quay lại màn hình Login.

---

### 1.3. `profile_screen.dart` : Màn hình Hồ Sơ Cá Nhân & Đổi Vai Trò
- **Mục tiêu:** Hiển thị thông tin định danh của người dùng và thực hiện **Nghiệp vụ đặc thù 1 (Dual-role Switch)**.
- **Thành phần giao diện:**
  1. Header: Avatar tròn, Họ tên, Email, Số điện thoại.
  2. Thẻ CCCD: Icon huy hiệu, hiển thị số CCCD đã đăng ký.
  3. Thẻ GPLX: Icon vô lăng xe, hiển thị mã bằng lái xe.
  4. **Thẻ Chế độ Hiện tại (Nghiệp vụ 1):**
     - Hiển thị: Đang ở chế độ *"Khách thuê (Renter)"* hoặc *"Chủ xe (Owner)"*.
     - **Nút bấm "CHUYỂN CHẾ ĐỘ" (Switch Role):**
       - Khi nhấn: Gọi `AuthService.switchRole(newRole)`.
       - Tự động hoán đổi: Nếu đang là `ROLE_OWNER` thì đổi sang `ROLE_RENTER` và ngược lại.
       - Hiển thị SnackBar thông báo: *"Đã chuyển sang chế độ Chủ xe / Khách thuê"*.
       - Cập nhật lại giao diện ngay lập tức.
  5. Nút *"ĐĂNG XUẤT"*:
     - Xoá token bằng `ApiClient.clearToken()`.
     - Điều hướng quay về `LoginScreen` (`pushAndRemoveUntil`).

---

## 2. Các Service & Model Đã Có Sẵn Để Sử Dụng:
- **Service:** `lib/data/services/auth_service.dart`:
  - `AuthService.login(email, password)`
  - `AuthService.register(...)`
  - `AuthService.getCurrentUser()`
  - `AuthService.switchRole(newRole)`
- **Model:** `lib/data/models/user_model.dart`
- **Màu sắc & Style:** `lib/core/constants/app_colors.dart`
