import 'dart:convert';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationService {
  // Lấy danh sách tất cả thông báo của người dùng hiện tại
  static Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await ApiClient.get(ApiEndpoints.notifications);
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((e) => NotificationModel.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      // Có thể log hoặc trả về danh sách rỗng
    }
    return [];
  }

  // Đếm số lượng thông báo chưa đọc
  static Future<int> getUnreadCount() async {
    try {
      final response = await ApiClient.get(ApiEndpoints.unreadCount);
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['success'] == true && data['data'] != null) {
          final count = data['data']['unread_count'];
          if (count is num) return count.toInt();
        }
      }
    } catch (_) {}
    return 0;
  }

  // Đánh dấu thông báo đã đọc theo ID
  static Future<bool> markAsRead(int notificationId) async {
    try {
      final response = await ApiClient.put(
        ApiEndpoints.markNotificationRead(notificationId),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['success'] == true;
      }
    } catch (_) {}
    return false;
  }
}
