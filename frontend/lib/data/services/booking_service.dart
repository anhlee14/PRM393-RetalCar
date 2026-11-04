import 'dart:convert';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/booking_model.dart';

class BookingService {
  // Feature 1: Đặt xe kèm tài xế
  static Future<Map<String, dynamic>> createBooking({
    required int vehicleId,
    required DateTime startDate,
    required DateTime endDate,
    bool withDriver = false,
    String? pickupAddress,
    String? returnAddress,
  }) async {
    try {
      final response = await ApiClient.post(
        ApiEndpoints.bookings,
        body: {
          'vehicle_id': vehicleId,
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'with_driver': withDriver,
          'pickup_address': pickupAddress,
          'return_address': returnAddress,
        },
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': BookingModel.fromJson(data['data'])};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Đặt xe thất bại'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối máy chủ: $e'};
    }
  }

  static Future<List<BookingModel>> getRenterBookings() async {
    try {
      final response = await ApiClient.get(ApiEndpoints.renterBookings);
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List).map((e) => BookingModel.fromJson(e)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<List<BookingModel>> getOwnerBookings() async {
    try {
      final response = await ApiClient.get(ApiEndpoints.ownerBookings);
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List).map((e) => BookingModel.fromJson(e)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<BookingModel?> getBookingById(int id) async {
    try {
      final response = await ApiClient.get('${ApiEndpoints.bookings}/$id');
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['success'] == true && data['data'] != null) {
          return BookingModel.fromJson(data['data']);
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> confirmBooking(int id) async {
    try {
      final response = await ApiClient.put(ApiEndpoints.confirmBooking(id));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> startTrip(int id) async {
    try {
      final response = await ApiClient.put(ApiEndpoints.startBooking(id));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> completeBooking(int id) async {
    try {
      final response = await ApiClient.put(ApiEndpoints.completeBooking(id));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
