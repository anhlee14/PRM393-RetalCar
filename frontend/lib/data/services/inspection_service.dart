import 'dart:convert';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/inspection_model.dart';

class InspectionService {
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
  }

  // Feature 3: Lấy dữ liệu đối chiếu Before - After
  static Future<InspectionComparisonModel?> getComparison(int bookingId) async {
    final response = await ApiClient.get(ApiEndpoints.inspectionComparison(bookingId));
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data['success'] == true && data['data'] != null) {
        return InspectionComparisonModel.fromJson(data['data']);
      }
    }
    return null;
  }

  static Future<bool> confirmInspection(int id) async {
    final response = await ApiClient.put(ApiEndpoints.confirmInspection(id));
    return response.statusCode == 200;
  }
}

