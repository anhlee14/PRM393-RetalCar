import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/notification_service.dart';
import 'renter_route_map_screen.dart';
import 'owner_snapshot_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  int _unreadCount = 0;
  UserModel? _currentUser;

  bool get _isOwner => _currentUser?.role == 'ROLE_OWNER';

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    final user = await AuthService.getCurrentUser();
    final list = await NotificationService.getNotifications();
    final count = await NotificationService.getUnreadCount();

    if (mounted) {
      setState(() {
        _currentUser = user;
        _notifications = list;
        _unreadCount = count;
        _isLoading = false;
      });
    }
  }

  void _openGpsForRole(int bookingId) {
    if (_isOwner) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OwnerSnapshotScreen(bookingId: bookingId),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RenterRouteMapScreen(bookingId: bookingId),
        ),
      );
    }
  }

  Future<void> _handleNotificationTap(NotificationModel noti) async {
    if (!noti.isRead) {
      await NotificationService.markAsRead(noti.id);
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == noti.id);
        if (index != -1) {
          _notifications[index] = NotificationModel(
            id: noti.id,
            title: noti.title,
            message: noti.message,
            type: noti.type,
            isRead: true,
            referenceId: noti.referenceId,
            createdAt: noti.createdAt,
          );
        }
        if (_unreadCount > 0) _unreadCount--;
      });
    }

    if (!mounted) return;

    final targetBookingId = noti.referenceId ?? 1;

    // Hiển thị BottomSheet chi tiết thông báo theo đúng vai trò người dùng
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildTypeBadge(noti.type),
                const Spacer(),
                Text(
                  _formatDate(noti.createdAt),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              noti.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              noti.message,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            if (noti.type == 'GPS_WARNING' || noti.title.contains('GPS'))
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openGpsForRole(targetBookingId);
                  },
                  icon: Icon(_isOwner ? Icons.radar_rounded : Icons.my_location),
                  label: Text(
                    _isOwner
                        ? 'KIỂM TRA SNAPSHOT VỊ TRÍ XE #BK-$targetBookingId'
                        : 'MỞ BẢN ĐỒ & PING GPS NGAY (#BK-$targetBookingId)',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              )
            else if (noti.referenceId != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openGpsForRole(noti.referenceId!);
                  },
                  icon: Icon(_isOwner ? Icons.shield_outlined : Icons.map_outlined),
                  label: Text(
                    _isOwner
                        ? 'Xem Định vị Snapshot Xe (#BK-${noti.referenceId})'
                        : 'Xem Lộ Trình GPS Chuyến Xe (#BK-${noti.referenceId})',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (type) {
      case 'GPS_WARNING':
        bg = AppColors.danger.withValues(alpha: 0.12);
        fg = AppColors.danger;
        label = 'Cảnh báo GPS';
        icon = Icons.warning_amber_rounded;
        break;
      case 'BOOKING_STATUS':
        bg = AppColors.primary.withValues(alpha: 0.12);
        fg = AppColors.primary;
        label = 'Đơn thuê xe';
        icon = Icons.assignment_outlined;
        break;
      case 'INSPECTION_UPDATE':
        bg = Colors.teal.withValues(alpha: 0.12);
        fg = Colors.teal;
        label = 'Bàn giao xe';
        icon = Icons.camera_alt_outlined;
        break;
      case 'PAYMENT_UPDATE':
        bg = AppColors.success.withValues(alpha: 0.12);
        fg = AppColors.success;
        label = 'Thanh toán';
        icon = Icons.account_balance_wallet_outlined;
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.12);
        fg = Colors.grey.shade800;
        label = 'Hệ thống';
        icon = Icons.notifications_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} ${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thông Báo Hệ Thống'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: _fetchNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchNotifications,
              child: _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_outlined, size: 72, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'Chưa có thông báo nào',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bạn sẽ nhận thông báo khi có cập nhật về chuyến xe,\nbiên bản kiểm định hoặc cảnh báo GPS.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _fetchNotifications,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tải lại'),
                          )
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final noti = _notifications[index];
                        return _buildNotificationCard(noti);
                      },
                    ),
            ),
    );
  }

  Widget _buildNotificationCard(NotificationModel noti) {
    final isGpsWarning = noti.type == 'GPS_WARNING';

    return InkWell(
      onTap: () => _handleNotificationTap(noti),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: noti.isRead
              ? Colors.white
              : (isGpsWarning ? Colors.red.shade50 : Colors.blue.shade50.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isGpsWarning
                ? AppColors.danger.withValues(alpha: 0.5)
                : (noti.isRead ? AppColors.border : AppColors.primary.withValues(alpha: 0.3)),
            width: isGpsWarning ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isGpsWarning
                    ? AppColors.danger.withValues(alpha: 0.15)
                    : (noti.type == 'PAYMENT_UPDATE'
                        ? AppColors.success.withValues(alpha: 0.15)
                        : (noti.type == 'INSPECTION_UPDATE'
                            ? Colors.teal.withValues(alpha: 0.15)
                            : AppColors.primary.withValues(alpha: 0.15))),
              ),
              child: Icon(
                isGpsWarning
                    ? Icons.warning_amber_rounded
                    : (noti.type == 'PAYMENT_UPDATE'
                        ? Icons.account_balance_wallet_outlined
                        : (noti.type == 'INSPECTION_UPDATE'
                            ? Icons.camera_alt_outlined
                            : Icons.assignment_outlined)),
                color: isGpsWarning
                    ? AppColors.danger
                    : (noti.type == 'PAYMENT_UPDATE'
                        ? AppColors.success
                        : (noti.type == 'INSPECTION_UPDATE' ? Colors.teal : AppColors.primary)),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildTypeBadge(noti.type),
                      const Spacer(),
                      if (!noti.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                        ),
                      Text(
                        _formatDate(noti.createdAt),
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    noti.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: noti.isRead ? FontWeight.w600 : FontWeight.bold,
                      color: isGpsWarning ? AppColors.danger : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    noti.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
