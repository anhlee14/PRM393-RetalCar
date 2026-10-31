class ApiEndpoints {
  // Đối với Android Emulator dùng: 'http://10.0.2.2:8080'
  // Đối với iOS Simulator hoặc Web dùng: 'http://localhost:8080'
  // Đối với máy thật cắm cáp / cùng mạng Wi-Fi: thay bằng IP LAN (VD: 'http://192.168.1.10:8080')
  static const String baseUrl = 'http://10.0.2.2:8080';

  // Auth
  static const String login = '$baseUrl/api/auth/login';
  static const String register = '$baseUrl/api/auth/register';
  static const String switchRole = '$baseUrl/api/auth/switch-role';
  static const String currentUser = '$baseUrl/api/auth/me';

  // Vehicles & Matching
  static const String vehicles = '$baseUrl/api/vehicles';
  static const String ownerVehicles = '$baseUrl/api/vehicles/owner';
  static const String matchVehicles = '$baseUrl/api/vehicles/match';

  // Bookings
  static const String bookings = '$baseUrl/api/bookings';
  static const String renterBookings = '$baseUrl/api/bookings/renter';
  static const String ownerBookings = '$baseUrl/api/bookings/owner';
  static String confirmBooking(int id) => '$baseUrl/api/bookings/$id/confirm';
  static String startBooking(int id) => '$baseUrl/api/bookings/$id/start';
  static String completeBooking(int id) => '$baseUrl/api/bookings/$id/complete';

  // Payments (Màn hình Thanh toán & Hóa đơn)
  static const String checkoutPayment = '$baseUrl/api/payments/checkout';
  static String bookingPayments(int bookingId) => '$baseUrl/api/payments/booking/$bookingId';

  // Inspections (Before & After)
  static const String inspections = '$baseUrl/api/inspections';
  static String inspectionComparison(int bookingId) => '$baseUrl/api/inspections/$bookingId/comparison';
  static String confirmInspection(int id) => '$baseUrl/api/inspections/$id/confirm';

  // GPS & Privacy
  static const String gpsPing = '$baseUrl/api/gps/ping';
  static String renterRoute(int bookingId) => '$baseUrl/api/gps/renter-route/$bookingId';
  static String ownerSnapshot(int bookingId) => '$baseUrl/api/gps/owner-snapshot/$bookingId';
  static String gpsStatus(int bookingId) => '$baseUrl/api/gps/status/$bookingId';

  // Notifications
  static const String notifications = '$baseUrl/api/notifications';
  static const String unreadCount = '$baseUrl/api/notifications/unread-count';
  static String markNotificationRead(int id) => '$baseUrl/api/notifications/$id/read';

  // File Upload
  static const String uploadFile = '$baseUrl/api/files/upload';
}
