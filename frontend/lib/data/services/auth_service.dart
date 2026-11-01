import 'dart:convert';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await ApiClient.post(
        ApiEndpoints.login,
        body: {'username': username, 'password': password},
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && data['success'] == true) {
        final token = data['data']['token'];
        final refreshToken = data['data']['refresh_token'];
        await ApiClient.saveTokens(accessToken: token, refreshToken: refreshToken);
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Đăng nhập thất bại'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Không thể kết nối đến máy chủ Backend ($e). Hãy đảm bảo Backend đang chạy!'};
    }
  }

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String role = 'ROLE_RENTER',
    String? cccd,
    String? driverLicense,
  }) async {
    try {
      final response = await ApiClient.post(
        ApiEndpoints.register,
        body: {
          'full_name': fullName,
          'email': email,
          'phone': phone,
          'password': password,
          'role': role,
          'cccd_number': cccd,
          'driver_license': driverLicense,
        },
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': UserModel.fromJson(data['data'])};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Đăng ký thất bại'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối máy chủ: $e'};
    }
  }

  static Future<UserModel?> getCurrentUser() async {
    try {
      final response = await ApiClient.get(ApiEndpoints.currentUser);
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['success'] == true && data['data'] != null) {
          return UserModel.fromJson(data['data']);
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> switchRole(String targetRole) async {
    try {
      final response = await ApiClient.put(
        ApiEndpoints.switchRole,
        body: {'target_role': targetRole},
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? cccdNumber,
    String? driverLicense,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (fullName != null) body['full_name'] = fullName;
      if (phone != null) body['phone'] = phone;
      if (avatarUrl != null) body['avatar_url'] = avatarUrl;
      if (cccdNumber != null) body['cccd_number'] = cccdNumber;
      if (driverLicense != null) body['driver_license'] = driverLicense;

      final response = await ApiClient.put(
        ApiEndpoints.updateProfile,
        body: body,
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': UserModel.fromJson(data['data'])};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Cập nhật hồ sơ thất bại'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối máy chủ: $e'};
    }
  }
}
