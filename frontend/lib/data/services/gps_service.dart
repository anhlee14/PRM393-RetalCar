import 'dart:convert';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/gps_model.dart';

class GpsService {
  // Feature 2: Người thuê gửi toạ độ (Bắt buộc tối đa 1 tiếng / lần khi đơn đang ONGOING)
  static Future<bool> pingGps({
    required int bookingId,
    required double latitude,
    required double longitude,
    double speed = 0.0,
  }) async {
    final result = await pingGpsDetailed(
      bookingId: bookingId,
      latitude: latitude,
      longitude: longitude,
      speed: speed,
    );
    return result['success'] == true;
  }

  static Future<Map<String, dynamic>> pingGpsDetailed({
    required int bookingId,
    required double latitude,
    required double longitude,
    double speed = 0.0,
  }) async {
    try {
      final response = await ApiClient.post(
        ApiEndpoints.gpsPing,
        body: {
          'booking_id': bookingId,
          'latitude': latitude,
          'longitude': longitude,
          'speed': speed,
        },
      );
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Cập nhật tọa độ GPS thành công',
          'data': data['data'] != null ? GpsLogModel.fromJson(data['data']) : null,
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Không thể gửi tọa độ GPS',
      };
    } catch (e) {
      return {
        'success': false,
        'network_error': true,
        'message': 'Không thể kết nối máy chủ GPS',
      };
    }
  }

  // Feature 2: Người thuê xem FULL lộ trình
  static Future<List<GpsLogModel>> getRenterFullRoute(int bookingId) async {
    final response = await ApiClient.get(ApiEndpoints.renterRoute(bookingId));
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data['success'] == true && data['data'] != null) {
        return (data['data'] as List).map((e) => GpsLogModel.fromJson(e)).toList();
      }
    }
    return [];
  }

  // Feature 2: Chủ xe chỉ xem Snapshot toạ độ tức thời + Giới hạn 20 lần / ngày (-1 lượt mỗi khi gọi)
  static Future<Map<String, dynamic>> getOwnerSnapshot(int bookingId) async {
    final response = await ApiClient.get(ApiEndpoints.ownerSnapshot(bookingId));
    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200 && data['success'] == true) {
      return {
        'success': true,
        'data': GpsSnapshotModel.fromJson(data['data']),
      };
    } else if (response.statusCode == 429) {
      return {
        'success': false,
        'quota_exceeded': true,
        'message': data['message'] ?? 'Bạn đã hết 20 lượt kiểm tra vị trí hôm nay',
      };
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Lỗi khi lấy vị trí xe',
      };
    }
  }

  // Feature 2: Kiểm tra cảnh báo quá 1 tiếng & thông tin Quota hiện tại (KHÔNG trừ lượt của Chủ xe)
  static Future<Map<String, dynamic>> checkGpsStatus(int bookingId) async {
    final response = await ApiClient.get(ApiEndpoints.gpsStatus(bookingId));
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['data'] ?? {};
    }
    return {};
  }
}
