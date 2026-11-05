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

  static Future<List<VehicleModel>> getPendingVehicles() async {
    final response = await ApiClient.get(ApiEndpoints.pendingVehicles);
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
    final response = await ApiClient.get(ApiEndpoints.vehicleDetail(id));
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data['success'] == true && data['data'] != null) {
        return VehicleModel.fromJson(data['data']);
      }
    }
    return null;
  }

  // Feature 4: Gọi API Matching tìm xe theo tỉ lệ % khớp (Type-safe Model cho ExploreScreen)
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

  // Tạo xe mới (kèm cấu hình có tài xế)
  static Future<Map<String, dynamic>> createVehicle({
    required String name,
    required String brand,
    required String licensePlate,
    required String vehicleType,
    required String transmission,
    required String fuelType,
    required double basePricePerDay,
    required bool hasDriverOption,
    required double driverFeePerDay,
    int seats = 4,
    int? modelYear,
    String? description,
    String? address,
    String? thumbnailUrl,
    List<String>? imageUrls,
  }) async {
    try {
      final body = {
        'name': name,
        'brand': brand,
        'license_plate': licensePlate,
        'vehicle_type': vehicleType,
        'transmission': transmission,
        'fuel_type': fuelType,
        'base_price_per_day': basePricePerDay,
        'has_driver_option': hasDriverOption,
        'driver_fee_per_day': hasDriverOption ? driverFeePerDay : 0.0,
        'seats': seats,
        'model_year': modelYear ?? 2024,
        'description': description ?? '',
        'address': address ?? '',
        'thumbnail_url': thumbnailUrl ?? (imageUrls != null && imageUrls.isNotEmpty ? imageUrls.first : ''),
        'image_urls': imageUrls ?? [],
      };

      final response = await ApiClient.post(ApiEndpoints.vehicles, body: body);
      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'Đăng xe thành công', 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Đăng xe thất bại'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Cập nhật thông tin xe
  static Future<Map<String, dynamic>> updateVehicle(
    int id, {
    required String name,
    required String brand,
    required String licensePlate,
    required String vehicleType,
    required String transmission,
    required String fuelType,
    required double basePricePerDay,
    required bool hasDriverOption,
    required double driverFeePerDay,
    int seats = 4,
    int? modelYear,
    String? description,
    String? address,
    String? thumbnailUrl,
    List<String>? imageUrls,
  }) async {
    try {
      final body = {
        'name': name,
        'brand': brand,
        'license_plate': licensePlate,
        'vehicle_type': vehicleType,
        'transmission': transmission,
        'fuel_type': fuelType,
        'base_price_per_day': basePricePerDay,
        'has_driver_option': hasDriverOption,
        'driver_fee_per_day': hasDriverOption ? driverFeePerDay : 0.0,
        'seats': seats,
        'model_year': modelYear ?? 2024,
        'description': description ?? '',
        'address': address ?? '',
        'thumbnail_url': thumbnailUrl ?? (imageUrls != null && imageUrls.isNotEmpty ? imageUrls.first : ''),
        'image_urls': imageUrls ?? [],
      };

      final response = await ApiClient.put(ApiEndpoints.vehicleDetail(id), body: body);
      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Cập nhật xe thành công', 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Cập nhật thất bại'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Xóa xe (có kiểm tra đơn thuê active)
  static Future<Map<String, dynamic>> deleteVehicle(int id) async {
    try {
      final response = await ApiClient.delete(ApiEndpoints.vehicleDetail(id));
      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Xóa xe thành công'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Không thể xóa xe'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Admin duyệt xe cho thuê
  // Admin t? ch?i duy?t xe
  static Future<Map<String, dynamic>> rejectVehicle(int id) async {
    try {
      final response = await ApiClient.put(ApiEndpoints.rejectVehicle(id));
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, 'message': '? t? ch?i duy?t xe'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'T? ch?i xe th?t b?i'};
      }
    } catch (e) {
      return {'success': false, 'message': 'L?i k?t n?i: $e'};
    }
  }

    static Future<Map<String, dynamic>> approveVehicle(int id) async {
    try {
      final response = await ApiClient.put(ApiEndpoints.approveVehicle(id));
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Duyệt xe thành công, xe đã sẵn sàng cho thuê'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Duyệt xe thất bại'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
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
