# PHÂN HỆ: ĐẶT XE, THANH TOÁN & LỊCH SỬ CHUYẾN ĐI (BOOKING & CHECKOUT)
**Người phụ trách:** 👤 **Thành viên 2**  
**Môn học:** PRM393 - Mobile Application Development (FPT University)

---

## 1. Danh Sách Màn Hình Cần Tạo (`lib/features/booking/screens/`):

### 1.1. `booking_form_screen.dart` : Màn Hình Tạo Đơn Đặt Xe
- **Mục tiêu:** Cho phép khách thuê cấu hình thời gian thuê xe và áp dụng **Nghiệp vụ đặc thù 1 (Tuỳ chọn thuê kèm tài xế)**.
- **Thành phần giao diện:**
  1. Tóm tắt xe: Ảnh nhỏ, Tên xe, Biển số, Giá gốc/ngày.
  2. **Bộ chọn Thời gian thuê:**
     - Sử dụng `showDateRangePicker` để chọn Ngày bắt đầu $\rightarrow$ Ngày kết thúc.
     - Hiển thị tổng số ngày thuê: `X ngày`.
  3. **Tuỳ chọn Nghiệp vụ 1 (Thuê cả lái xe):**
     - Hiển thị `SwitchListTile`: *"Thuê kèm tài xế riêng (+X đ/ngày)"*.
     - Nếu xe của chủ không hỗ trợ tài xế (`vehicle.hasDriverOption == false`): Làm mờ Switch và ghi chú *"Xe này chủ xe chỉ cho thuê tự lái"*.
  4. Địa điểm nhận xe (Textfield hoặc chọn trên bản đồ).
  5. **Bảng Tạm tính Chi phí Thời gian thực:**
     - Tiền thuê xe: $\text{BasePrice} \times \text{Days}$
     - Phụ phí tài xế: $\text{DriverFee} \times \text{Days}$ (nếu bật Switch)
     - **TỔNG TIỀN:** $\text{TotalPrice} = (\text{BasePrice} + \text{DriverFee}) \times \text{Days}$
  6. Nút bấm: *"TIẾP TỤC ĐẾN THANH TOÁN"* $\rightarrow$ Gọi `BookingService.createBooking(...)`. Khi tạo đơn thành công $\rightarrow$ Điều hướng sang `CheckoutPaymentScreen(booking: newBooking)`.

---

### 1.2. `checkout_payment_screen.dart` : Màn Hình Hóa Đơn & Thanh Toán Cọc (Checkout)
- **Mục tiêu:** Xử lý thủ tục tài chính, hiển thị hóa đơn chi tiết, tỉ lệ đặt cọc 30% và các phương thức thanh toán.
- **Thành phần giao diện:**
  1. Mã đơn thuê: `#BK-XXXX` & Thông tin xe đã đặt.
  2. Thời gian chuyến đi: Từ ngày ... đến ngày ... (X ngày).
  3. **Bảng Chi Tiết Hóa Đơn Tài Chính:**
     - Tổng giá trị đơn thuê: `100%` (VD: *3.000.000 đ*).
     - **TIỀN CỌC CẦN THANH TOÁN NGAY (30%):** (VD: *900.000 đ*).
     - **TIỀN THANH TOÁN KHI NHẬN XE (70%):** (VD: *2.100.000 đ*).
  4. **Lựa chọn Phương thức Thanh toán:**
     - Radio 1: **Chuyển khoản QR (VietQR)** (Có hình mã QR động, tên chủ tài khoản, số tài khoản, cú pháp chuyển tiền).
     - Radio 2: **Ví MoMo / VNPay**.
     - Radio 3: **Tiền mặt khi nhận bàn giao xe**.
  5. Cam kết an toàn & chính sách hoàn cọc (Checkbox xác nhận đồng ý điều khoản).
  6. Nút bấm: *"XÁC NHẬN ĐẶT CỌC (900.000 đ)"*:
     - Gọi `PaymentService.processCheckout(bookingId: ..., paymentMethod: ..., amount: ...)`.
     - Thành công: Hiển thị Dialog chúc mừng *"Thanh toán cọc thành công!"*, chuyển hướng sang `BookingHistoryScreen()`.

---

### 1.3. `booking_history_screen.dart` : Danh Sách Chuyến Đi Của Khách Thuê
- **Mục tiêu:** Quản lý lịch sử các chuyến đi của khách thuê, theo dõi trạng thái và dẫn lối sang các phân hệ Giám sát GPS / Thẩm định xe.
- **Thành phần giao diện:**
  1. TabFilter: `Tất cả`, `Chờ duyệt`, `Đang đi`, `Hoàn thành`.
  2. Danh sách chuyến đi (`ListView.builder`):
     - Mỗi thẻ hiển thị:
       - Mã đơn, tên xe, biển số.
       - Trạng thái đơn: Badge màu tương ứng (`PENDING`: Vàng, `APPROVED`: Xanh dương, `IN_PROGRESS`: Xanh lá, `COMPLETED`: Xám).
       - Tổng tiền & Số tiền đã cọc.
       - Thẻ hiển thị: *"🚗 Có tài xế"* hoặc *"🚙 Tự lái"*.
     - **Các nút chức năng tương tác nhanh theo trạng thái:**
       - Nút *"Lộ trình GPS"* $\rightarrow$ Mở `RenterRouteMapScreen(bookingId: b.id)`.
       - Nút *"Biên bản nhận xe (Check-in)"* $\rightarrow$ Mở `PhotoInspectionScreen(bookingId: b.id, stage: 'CHECK_IN')`.
       - Nút *"Biên bản trả xe (Check-out)"* $\rightarrow$ Mở `PhotoInspectionScreen(bookingId: b.id, stage: 'CHECK_OUT')`.
       - Nút *"Đối chiếu Before/After"* $\rightarrow$ Mở `ComparisonScreen(bookingId: b.id)`.

---

## 2. Các Service & Model Đã Có Sẵn Để Sử Dụng:
- **Service:**
  - `lib/data/services/booking_service.dart`: `createBooking()`, `getRenterBookings()`, `cancelBooking()`
  - `lib/data/services/payment_service.dart`: `processCheckout()`, `getPaymentDetails()`
- **Model:** `lib/data/models/booking_model.dart`
- **Tiện ích:** `lib/core/utils/currency_formatter.dart`
- **Màu sắc & Style:** `lib/core/constants/app_colors.dart`
