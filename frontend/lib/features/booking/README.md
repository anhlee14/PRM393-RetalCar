# PHÂN HỆ: ĐẶT XE, THANH TOÁN CỌC & LỊCH SỬ CHUYẾN ĐI (BOOKING & CHECKOUT)
**Người phụ trách:** 👤 **Thành viên 2**  
**Môn học:** PRM393 - Mobile Application Development (FPT University)  
**Kiến trúc:** Feature-First Clean Architecture

---

## 1. Danh Sách Màn Hình Cần Làm (`lib/features/booking/screens/`):

### 1.1. `booking_form_screen.dart` : Màn Hình Tạo Đơn Đặt Xe
- **File:** `lib/features/booking/screens/booking_form_screen.dart`
- **Mục tiêu:** Cấu hình thời gian thuê xe và áp dụng **Nghiệp vụ đặc thù 1 (Tuỳ chọn thuê kèm tài xế riêng)**.
- **Thành phần giao diện (UI Components):**
  1. Thẻ Tóm tắt xe: Ảnh nhỏ, Tên xe, Biển số, Giá gốc/ngày.
  2. **Bộ chọn Thời gian thuê xe:**
     - Sử dụng `showDateRangePicker`: Chọn Ngày bắt đầu $\rightarrow$ Ngày kết thúc.
     - Hiển thị số ngày thuê: `X ngày`.
  3. **Tuỳ chọn Nghiệp vụ 1 (Thuê cả lái xe):**
     - `SwitchListTile: "Thuê kèm tài xế riêng (+X đ/ngày)"`.
     - Nếu xe không hỗ trợ tài xế (`vehicle.hasDriverOption == false`): Làm mờ Switch và ghi chú *"Xe này chủ xe chỉ cho thuê tự lái"*.
  4. Địa điểm nhận xe & Địa điểm trả xe: `TextFormField` (mặc định lấy địa chỉ của xe).
  5. **Bảng Tạm tính Chi phí Thời gian thực:**
     - Tiền thuê xe: $\text{BasePrice} \times \text{Days}$
     - Phụ phí tài xế: $\text{DriverFee} \times \text{Days}$ (nếu bật Switch)
     - **TỔNG TIỀN:** $\text{TotalPrice} = (\text{BasePrice} + \text{DriverFee}) \times \text{Days}$
     - **TIỀN CỌC 30%:** $\text{DepositAmount} = \text{TotalPrice} \times 30\%$
  6. Nút bấm: *"TIẾP TỤC ĐẾN THANH TOÁN CỌC"*:
     - Gọi `BookingService.createBooking(...)` (`POST /api/bookings`).
     - Khi tạo đơn thành công $\rightarrow$ Chuyển tiếp sang `CheckoutPaymentScreen(booking: newBooking)`.

---

### 1.2. `checkout_payment_screen.dart` : Màn Hình Hóa Đơn & Đặt Cọc (Checkout)
- **File:** `lib/features/booking/screens/checkout_payment_screen.dart`
- **Mục tiêu:** Xử lý thủ tục tài chính, hiển thị hóa đơn chi tiết, tỉ lệ đặt cọc 30% và các phương thức thanh toán.
- **Thành phần giao diện (UI Components):**
  1. Header: Mã đơn `#BK-XXXX` & Tên xe đã đặt.
  2. Thông tin thời gian thuê: Từ ngày ... đến ngày ... (X ngày).
  3. **Bảng Kê Hóa Đơn Tài Chính:**
     - Tổng giá trị chuyến đi (100%): `X đ`.
     - **TIỀN CỌC CẦN THANH TOÁN NGAY (30%):** Chữ to màu đỏ đậm (VD: *900.000 đ*).
     - **TIỀN THANH TOÁN KHI NHẬN XE (70%):** (VD: *2.100.000 đ*).
  4. **Lựa chọn Phương thức Thanh toán (`RadioListTile`):**
     - **Phương thức 1: Chuyển khoản QR (VietQR):**
       - Hiển thị hình ảnh mã QR ngân hàng động.
       - Tên chủ tài khoản: `NGUYEN VAN CHU XE`.
       - Số tài khoản: `190366889999` (Ngân hàng Techcombank / MB).
       - Cú pháp chuyển khoản: `AUTORENTAL BKXXXX`.
       - Nút *"Sao chép số tài khoản & nội dung"*.
     - **Phương thức 2: Ví điện tử MoMo / VNPay**.
     - **Phương thức 3: Tiền mặt khi nhận bàn giao chìa khóa xe**.
  5. Checkbox xác nhận điều khoản: *"Tôi đồng ý với quy định cọc và chính sách bảo vệ xe"*.
  6. Nút bấm *"XÁC NHẬN ĐÃ THANH TOÁN CỌC"*:
     - Gọi `PaymentService.processCheckout(bookingId: ..., paymentMethod: ..., amount: ...)`.
     - Hiển thị Dialog chúc mừng *"Thanh toán cọc thành công!"*.
     - Điều hướng sang `BookingHistoryScreen()`.

---

### 1.3. `booking_history_screen.dart` : Danh Sách Chuyến Đi Của Khách Thuê
- **File:** `lib/features/booking/screens/booking_history_screen.dart`
- **Mục tiêu:** Quản lý toàn bộ lịch sử các cuốc xe (Tab 2), theo dõi trạng thái và dẫn lối sang các phân hệ Giám sát GPS hoặc Thẩm định xe.
- **Thành phần giao diện (UI Components):**
  1. TabFilter: `Tất cả`, `Chờ duyệt`, `Đang đi (Ongoing)`, `Hoàn thành`.
  2. Danh sách chuyến đi (`ListView.builder`):
     - Mỗi thẻ đơn hiển thị:
       - Mã đơn, tên xe, ngày thuê.
       - Chip trạng thái:
         - Vàng: `PENDING` (Chờ chủ xe duyệt).
         - Xanh dương: `CONFIRMED` (Đã duyệt & Đã cọc).
         - Xanh lá: `ONGOING` (Đang trong hành trình di chuyển).
         - Xám: `COMPLETED` (Đã hoàn tất trả xe & hoàn cọc).
       - Tổng chi phí & Số tiền đã cọc.
       - Thẻ hiển thị: *"🚗 Có tài xế"* hoặc *"🚙 Tự lái"*.
     - **Các nút chức năng tương tác nhanh theo trạng thái:**
       - Nút *"Lộ trình GPS"* $\rightarrow$ Mở `RenterRouteMapScreen(bookingId: b.id)`.
       - Nút *"Biên bản nhận xe (Check-in)"* $\rightarrow$ Mở `PhotoInspectionScreen(bookingId: b.id, stage: 'CHECK_IN')`.
       - Nút *"Biên bản trả xe (Check-out)"* $\rightarrow$ Mở `PhotoInspectionScreen(bookingId: b.id, stage: 'CHECK_OUT')`.
       - Nút *"Đối chiếu Before/After"* $\rightarrow$ Mở `ComparisonScreen(bookingId: b.id)`.

---

## 2. Hướng Dẫn Gọi API & Kết Nối Dữ Liệu:

```dart
// 1. Tạo đơn đặt xe (POST /api/bookings):
final booking = await BookingService.createBooking(
  vehicleId: vehicle.id,
  startDate: startDate,
  endDate: endDate,
  withDriver: withDriver,
  pickupAddress: pickupAddress,
);

// 2. Thanh toán đặt cọc 30% (POST /api/payments/checkout):
final paymentResult = await PaymentService.processCheckout(
  bookingId: booking.id,
  paymentMethod: 'VIETQR',
  amount: booking.depositAmount,
);

// 3. Lấy danh sách chuyến đi của khách (GET /api/bookings/my-history):
List<BookingModel> myBookings = await BookingService.getRenterBookings();
```

---

## 3. Các File Đã Có Sẵn Trong Dự Án Để Dùng Ngay:
- Service: `lib/data/services/booking_service.dart` và `lib/data/services/payment_service.dart`
- Model: `lib/data/models/booking_model.dart`
- Tiện ích định dạng tiền: `lib/core/utils/currency_formatter.dart`
- Màu sắc: `lib/core/constants/app_colors.dart`
