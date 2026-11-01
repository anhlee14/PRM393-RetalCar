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

  static Future<VehicleModel?> getVehicleById(int id) async {
    final response = await ApiClient.get('${ApiEndpoints.vehicles}/$id');
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data['success'] == true && data['data'] != null) {
        return VehicleModel.fromJson(data['data']);
      }
    }
    return null;
  }

  // Feature 4: Gọi API Matching tìm xe theo tỉ lệ % khớp (Type-safe Model)
  static Future<List<VehicleMatchModel>> searchMatchingVehicles({
    double? budget,
    bool needDriver = false,
    double? userLat,
    double? userLng,
    String? vehicleType,
    double budgetWeight = 0.25,
    double distanceWeight = 0.20,
    double driverWeight = 0.30,
    double typeWeight = 0.15,
    double ratingWeight = 0.10,
  }) async {
    final body = {
      'need_driver': needDriver,
      'user_lat': userLat ?? 21.0131,
      'user_lng': userLng ?? 105.5255,
      'budget_weight': budgetWeight,
      'distance_weight': distanceWeight,
      'driver_weight': driverWeight,
      'type_weight': typeWeight,
      'rating_weight': ratingWeight,
    };
    if (budget != null && budget > 0) {
      body['budget'] = budget;
    }
    if (vehicleType != null && vehicleType.isNotEmpty && vehicleType != 'ALL') {
      body['vehicle_type'] = vehicleType;
    }

    final response = await ApiClient.post(
      ApiEndpoints.matchVehicles,
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data['success'] == true && data['data'] != null) {
        return (data['data'] as List)
            .map((e) => VehicleMatchModel.fromJson(e))
            .toList();
      }
    }
    return [];
  }

  // Feature 4: Gọi API Matching tìm xe theo tỉ lệ % khớp (Raw Map)
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

