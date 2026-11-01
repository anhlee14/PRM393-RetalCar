import 'package:flutter/foundation.dart';

class ApiEndpoints {
  // Tự động nhận diện nền tảng:
  // - Web (Chrome, Edge): 'http://localhost:8080'
  // - Android Emulator: 'http://10.0.2.2:8080'
  // - iOS Simulator / Desktop (Windows, macOS): 'http://localhost:8080'
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8080';
      default:
        return 'http://localhost:8080';
    }
  }

  // Auth
  static String get login => '$baseUrl/api/auth/login';
  static String get register => '$baseUrl/api/auth/register';
  static String get switchRole => '$baseUrl/api/auth/switch-role';
  static String get currentUser => '$baseUrl/api/auth/me';

  // Vehicles & Matching
  static String get vehicles => '$baseUrl/api/vehicles';
  static String get ownerVehicles => '$baseUrl/api/vehicles/owner';
  static String get matchVehicles => '$baseUrl/api/vehicles/match';

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
