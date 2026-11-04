import 'package:flutter/foundation.dart';

class ApiEndpoints {
  // Tự động nhận diện nền tảng:
  // - Nếu chạy trên Web (Chrome) hoặc Windows: dùng 'http://localhost:8080'
  // - Nếu chạy trên Android Emulator: dùng 'http://10.0.2.2:8080'
  // - Nếu cắm điện thoại thật qua USB/LAN: thay bằng IP LAN máy tính (VD: 'http://192.168.1.10:8080')
  static String get baseUrl => kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080';

  // Google OAuth Client ID
  static const String googleWebClientId =
      '983143606511-pc4cgo3077is1bujc48p50gbd2n22lff.apps.googleusercontent.com';

  // Auth & Profile
  static String get login => '$baseUrl/api/auth/login';
  static String get googleLogin => '$baseUrl/api/auth/google';
  static String get register => '$baseUrl/api/auth/register';
  static String get refreshToken => '$baseUrl/api/auth/refresh';
  static String get switchRole => '$baseUrl/api/auth/switch-role';
  static String get currentUser => '$baseUrl/api/auth/me';
  static String get updateProfile => '$baseUrl/api/users/me';

  // Vehicles & Matching
  static String get vehicles => '$baseUrl/api/vehicles';
  static String get ownerVehicles => '$baseUrl/api/vehicles/owner';
  static String get matchVehicles => '$baseUrl/api/vehicles/match';
  static String vehicleDetail(int id) => '$vehicles/$id';
  static String approveVehicle(int id) => '$vehicles/$id/approve';
  static String rejectVehicle(int id) => '$vehicles/$id/reject';

  // Bookings
  static String get bookings => '$baseUrl/api/bookings';
  static String get renterBookings => '$baseUrl/api/bookings/renter';
  static String get ownerBookings => '$baseUrl/api/bookings/owner';
  static String confirmBooking(int id) => '$baseUrl/api/bookings/$id/confirm';
  static String startBooking(int id) => '$baseUrl/api/bookings/$id/start';
  static String completeBooking(int id) => '$baseUrl/api/bookings/$id/complete';

  // Payments (Màn hình Thanh toán & Hóa đơn)
  static String get checkoutPayment => '$baseUrl/api/payments/checkout';
  static String bookingPayments(int bookingId) => '$baseUrl/api/payments/booking/$bookingId';

  // Inspections (Before & After)
  static String get inspections => '$baseUrl/api/inspections';
  static String inspectionComparison(int bookingId) => '$baseUrl/api/inspections/$bookingId/comparison';
  static String confirmInspection(int id) => '$baseUrl/api/inspections/$id/confirm';

  // GPS & Privacy
  static String get gpsPing => '$baseUrl/api/gps/ping';
  static String renterRoute(int bookingId) => '$baseUrl/api/gps/renter-route/$bookingId';
  static String ownerSnapshot(int bookingId) => '$baseUrl/api/gps/owner-snapshot/$bookingId';
  static String gpsStatus(int bookingId) => '$baseUrl/api/gps/status/$bookingId';

  // Notifications
  static String get notifications => '$baseUrl/api/notifications';
  static String get unreadCount => '$baseUrl/api/notifications/unread-count';
  static String markNotificationRead(int id) => '$baseUrl/api/notifications/$id/read';

  // File Upload
  static String get uploadFile => '$baseUrl/api/files/upload';
}
