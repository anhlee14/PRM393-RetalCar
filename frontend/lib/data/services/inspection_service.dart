import 'dart:convert';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/inspection_model.dart';

class InspectionService {
  // Upload ảnh kiểm định lên server
  static Future<String?> uploadPhoto(List<int> bytes, String filename) async {
    return await ApiClient.uploadFile(bytes, filename, folder: 'inspections');
  }

  // Feature 3: Gửi ảnh thẩm định xe (Check-in hoặc Check-out)
  static Future<Map<String, dynamic>> submitInspection({
    required int bookingId,
    required String stage, // CHECK_IN hoặc CHECK_OUT
    String? frontImg,
    String? rearImg,
    String? leftImg,
    String? rightImg,
    String? odoImg,
    String? fuelImg,
    double? odoKm,
    double? fuelLevelPercent,
    String? notes,
  }) async {
    try {
      final response = await ApiClient.post(
        ApiEndpoints.inspections,
        body: {
          'booking_id': bookingId,
          'stage': stage,
          'front_img': frontImg,
          'rear_img': rearImg,
          'left_img': leftImg,
          'right_img': rightImg,
          'odo_img': odoImg,
          'fuel_img': fuelImg,
          'odo_km': odoKm,
          'fuel_level_percent': fuelLevelPercent,
          'notes': notes,
        },
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': InspectionModel.fromJson(data['data'])};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Thẩm định thất bại'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối máy chủ: $e'};
    }
  }

  // Feature 3: Lấy dữ liệu đối chiếu Before - After
  static Future<InspectionComparisonModel?> getComparison(int bookingId) async {
    try {
      final response = await ApiClient.get(ApiEndpoints.inspectionComparison(bookingId));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['success'] == true && data['data'] != null) {
          return InspectionComparisonModel.fromJson(data['data']);
        }
      }
    } catch (_) {}
    return null;
  }

  // Feature 3: Ký xác nhận biên bản (Chủ xe hoặc Khách thuê)
  static Future<bool> confirmInspection(int id) async {
    try {
      final response = await ApiClient.put(ApiEndpoints.confirmInspection(id));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
