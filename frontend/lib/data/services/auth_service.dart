import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
        String msg = data['message'] ?? 'Đăng nhập thất bại';
        if (msg.contains('Bad credentials') || msg.contains('Unauthorized')) {
          msg = 'Tài khoản hoặc mật khẩu không chính xác!';
        }
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Không thể kết nối đến máy chủ Backend ($e). Hãy đảm bảo Backend đang chạy!',
      };
    }
  }

  static Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: kIsWeb ? null : ApiEndpoints.googleWebClientId,
        clientId: kIsWeb ? ApiEndpoints.googleWebClientId : null,
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return {'success': false, 'message': 'Đã hủy đăng nhập Google'};
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken ?? googleAuth.accessToken;

      if (idToken == null || idToken.isEmpty) {
        return {'success': false, 'message': 'Không thể lấy ID Token từ Google. Vui lòng thử lại.'};
      }

      debugPrint('[Google Auth] Lấy token thành công, gửi sang Backend: ${ApiEndpoints.googleLogin}');
      final response = await ApiClient.post(
        ApiEndpoints.googleLogin,
        body: {
          'id_token': idToken,
          'email': googleUser.email,
          'full_name': googleUser.displayName,
          'avatar_url': googleUser.photoUrl,
        },
      );

      debugPrint('[Google Auth] Backend HTTP status: ${response.statusCode}, body: ${response.body}');
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && data['success'] == true) {
        final token = data['data']['token'];
        final refreshToken = data['data']['refresh_token'];
        await ApiClient.saveTokens(accessToken: token, refreshToken: refreshToken);
        debugPrint('[Google Auth] Đăng nhập hệ thống AutoRental thành công!');
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Đăng nhập Google thất bại'};
      }
    } catch (e, stack) {
      debugPrint('[Google Auth] Lỗi ngoại lệ: $e\n$stack');
      return {'success': false, 'message': 'Lỗi đăng nhập Google: $e'};
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
