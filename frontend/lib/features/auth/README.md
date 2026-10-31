# PHÂN HỆ: XÁC THỰC, TÀI KHOẢN & HỒ SƠ CÁ NHÂN (AUTH & USER PROFILE)
**Người phụ trách:** 👤 **Thành viên 1**  
**Môn học:** PRM393 - Mobile Application Development (FPT University)  
**Kiến trúc:** Feature-First Clean Architecture

---

## 1. Danh Sách Màn Hình Cần Làm (`lib/features/auth/screens/`):

### 1.1. `login_screen.dart` : Màn Hình Đăng Nhập (ĐÃ CÓ SẴN - GIỮ NGUYÊN)
- **Trạng thái:** Đã hoàn thiện sẵn làm chuẩn kết nối API.
- **Tính năng:**
  - Nhập Email hoặc Số điện thoại + Mật khẩu.
  - Gọi `AuthService.login(email, password)`.
  - Tự động lưu `token` (Access Token) và `refreshToken` vào `SharedPreferences` thông qua `ApiClient`.
  - Nút chuyển nhanh sang `RegisterScreen`.

---

### 1.2. `register_screen.dart` : Màn Hình Đăng Ký Tài Khoản Mới
- **File:** `lib/features/auth/screens/register_screen.dart`
- **Mục tiêu:** Đăng ký tài khoản người dùng kèm thông tin định danh (CCCD, GPLX) và chọn vai trò ban đầu.
- **Thành phần giao diện (UI Components):**
  1. Header: Logo ứng dụng AutoRental, tiêu đề *"ĐĂNG KÝ TÀI KHOẢN"*.
  2. Các trường nhập liệu (Form Fields):
     - `Họ và tên`: `TextFormField` (Validate: không để trống, tối thiểu 2 từ).
     - `Email`: `TextFormField` (Keyboard: email, Validate: regex email chuẩn).
     - `Số điện thoại`: `TextFormField` (Keyboard: phone, 10 chữ số).
     - `Mật khẩu`: `TextFormField` (Obscure text, icon con mắt ẩn/hiện, tối thiểu 6 ký tự).
     - `Số CCCD / CMND`: `TextFormField` (12 số căn cước công dân).
     - `Số Giấy phép lái xe (GPLX)`: `TextFormField` (Mã bằng lái xe B1, B2...).
     - `Lựa chọn vai trò ban đầu`: `ChoiceChip` hoặc `RadioGroup`:
       - `Khách thuê xe (ROLE_RENTER)` (mặc định)
       - `Chủ xe cho thuê (ROLE_OWNER)`
  3. Nút bấm:
     - Nút chính *"ĐĂNG KÝ NGAY"*:
       - Kiểm tra `_formKey.currentState!.validate()`.
       - Hiển thị hiệu ứng tải `CircularProgressIndicator` khi đang gọi API.
       - Gọi hàm: `AuthService.register(...)`.
       - **Thành công:** SnackBar xanh *"Đăng ký tài khoản thành công! Vui lòng đăng nhập"*, điều hướng `Navigator.pop(context)` về màn hình Đăng nhập.
       - **Thất bại:** SnackBar đỏ hiển thị thông báo lỗi chi tiết từ Backend (VD: *"Email đã được sử dụng"*).
     - Nút phụ: *"Đã có tài khoản? Đăng nhập ngay"* $\rightarrow$ Quay lại `LoginScreen`.

---

### 1.3. `profile_screen.dart` : Màn Hình Hồ Sơ Cá Nhân & Đổi Vai Trò
- **File:** `lib/features/auth/screens/profile_screen.dart`
- **Mục tiêu:** Quản lý thông tin định danh cá nhân, **cập nhật Profile (`PUT /api/users/me`)** và thực hiện **Nghiệp vụ đặc thù 1 (Chuyển đổi vai trò Dual-Role)**.
- **Thành phần giao diện (UI Components):**
  1. Header Profile:
     - Avatar tròn lớn (Hiển thị ảnh mạng từ `user.avatarUrl` hoặc icon mặc định).
     - Nút icon Camera nhỏ ở góc avatar để chọn ảnh đại diện mới.
     - Họ và tên, Email, Số điện thoại.
  2. Khung Thông tin Định danh:
     - Thẻ CCCD: Hiển thị số CCCD đã đăng ký.
     - Thẻ Giấy phép lái xe (GPLX): Hiển thị số bằng lái.
  3. **Thẻ Chế Độ Hoạt Động (Nghiệp vụ đặc thù 1):**
     - Hiển thị vai trò hiện tại: *"Chủ xe (Host)"* hoặc *"Khách thuê (Renter)"*.
     - **Nút "ĐỔI CHẾ ĐỘ" (Switch Mode):**
       - Khi bấm: Gọi `AuthService.switchRole(newRole)`.
       - Tự động hoán đổi: Nếu đang là Chủ xe $\rightarrow$ chuyển sang Khách thuê; nếu là Khách thuê $\rightarrow$ chuyển sang Chủ xe.
       - SnackBar thông báo: *"Đã chuyển sang chế độ Chủ xe / Khách thuê"*, re-render lại UI tức thời.
  4. Nút bấm *"CHỈNH SỬA PROFILE"*:
     - Mở hộp thoại (hoặc bottom sheet) cho phép sửa: Họ tên, Số điện thoại, đổi link avatar, cập nhật lại CCCD/GPLX.
     - Gọi API: `PUT /api/users/me` qua `AuthService.updateProfile(...)`.
  5. Nút bấm *"ĐĂNG XUẤT"*:
     - Xóa token: `ApiClient.clearToken()`.
     - Điều hướng quay về `LoginScreen` (`pushAndRemoveUntil`).

---

## 2. Hướng Dẫn Gọi API & Kết Nối Dữ Liệu:

```dart
// 1. Đăng ký tài khoản:
final result = await AuthService.register(
  fullName: fullName,
  email: email,
  phone: phone,
  password: password,
  role: selectedRole,
  cccdNumber: cccd,
  driverLicense: gplx,
);

// 2. Lấy thông tin cá nhân:
UserModel? currentUser = await AuthService.getCurrentUser();

// 3. Đổi vai trò (Chủ xe <-> Khách thuê):
bool ok = await AuthService.switchRole(targetRole);

// 4. Cập nhật Profile (PUT /api/users/me):
final res = await ApiClient.put('/api/users/me', body: {
  'fullName': newName,
  'phone': newPhone,
  'avatarUrl': newAvatar,
});
```

---

## 3. Các File Đã Có Sẵn Trong Dự Án Để Dùng Ngay:
- Service: `lib/data/services/auth_service.dart`
- Model: `lib/data/models/user_model.dart`
- Network: `lib/core/network/api_client.dart`
- Hằng số & Màu sắc: `lib/core/constants/app_colors.dart` và `lib/core/constants/api_endpoints.dart`
