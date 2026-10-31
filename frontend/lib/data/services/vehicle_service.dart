import 'dart:convert';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/vehicle_model.dart';

class VehicleService {
  static Future<List<VehicleModel>> getAvailableVehicles() async {
    final response = await ApiClient.get(ApiEndpoints.vehicles);
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data['success'] == true && data['data'] != null) {
        return (data['data'] as List).map((e) => VehicleModel.fromJson(e)).toList();
      }
    }
    return [];
  }

  static Future<List<VehicleModel>> getOwnerVehicles() async {
    final response = await ApiClient.get(ApiEndpoints.ownerVehicles);
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data['success'] == true && data['data'] != null) {
        return (data['data'] as List).map((e) => VehicleModel.fromJson(e)).toList();
      }
    }
    return [];
  }

  // Feature 4: Gọi API Matching tìm xe theo tỉ lệ % khớp
  static Future<List<Map<String, dynamic>>> matchVehicles({
    double? budget,
    bool needDriver = false,
    double? userLat,
    double? userLng,
    double budgetWeight = 0.25,
    double distanceWeight = 0.20,
    double driverWeight = 0.30,
  }) async {
    final response = await ApiClient.post(
      ApiEndpoints.matchVehicles,
      body: {
        'budget': budget,
        'need_driver': needDriver,
        'user_lat': userLat,
        'user_lng': userLng,
        'budget_weight': budgetWeight,
        'distance_weight': distanceWeight,
        'driver_weight': driverWeight,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data['success'] == true && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
    }
    return [];
  }
}

