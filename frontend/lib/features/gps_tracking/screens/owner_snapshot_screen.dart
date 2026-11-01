import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/gps_model.dart';
import '../../../data/services/gps_service.dart';
import 'renter_route_map_screen.dart';

class OwnerSnapshotScreen extends StatefulWidget {
  final int bookingId;
  const OwnerSnapshotScreen({super.key, this.bookingId = 1});

  @override
  State<OwnerSnapshotScreen> createState() => _OwnerSnapshotScreenState();
}

class _OwnerSnapshotScreenState extends State<OwnerSnapshotScreen> {
  GpsSnapshotModel? _snapshot;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isQuotaExceeded = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchSnapshot();
  }

  Future<void> _fetchSnapshot() async {
    setState(() {
      _isLoading = _snapshot == null;
      _isRefreshing = _snapshot != null;
      _errorMessage = '';
    });

    final res = await GpsService.getOwnerSnapshot(widget.bookingId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;

        if (res['success'] == true) {
          _snapshot = res['data'];
          _isQuotaExceeded = (_snapshot?.remainingChecksToday ?? 0) <= 0;
        } else if (res['quota_exceeded'] == true) {
          _isQuotaExceeded = true;
          _errorMessage = res['message'] ?? 'Đã sử dụng hết hạn mức kiểm tra hôm nay';
        } else {
          _errorMessage = res['message'] ?? 'Không thể tải vị trí xe';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _snapshot?.remainingChecksToday ?? (_isQuotaExceeded ? 0 : 20);
    final totalAllowed = _snapshot?.totalAllowedPerDay ?? 20;
    final progress = totalAllowed > 0 ? (remaining / totalAllowed).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Vị Trí Xe #${widget.bookingId} (Chủ Xe)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.route),
            tooltip: 'Xem giao diện Khách thuê',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RenterRouteMapScreen(bookingId: widget.bookingId),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _isQuotaExceeded ? () async {} : _fetchSnapshot,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. THANH ĐO QUOTA 20 LẦN / NGÀY
                    _buildQuotaCard(remaining, totalAllowed, progress),

                    const SizedBox(height: 16),

                    // 2. KHÓA CẢNH BÁO NẾU HẾT LƯỢT (HTTP 429)
                    if (_isQuotaExceeded) ...[
                      _buildQuotaExceededWarning(),
                      const SizedBox(height: 16),
                    ],

                    // 3. KHUNG BẢN ĐỒ SNAPSHOT TỨC THỜI (TUYỆT ĐỐI KHÔNG HIỂN THỊ ĐƯỜNG ĐI)
                    _buildSnapshotMapCard(),

                    const SizedBox(height: 16),

                    // 4. THÔNG TIN CHI TIẾT TỨC THỜI CỦA XE
                    _buildVehicleInfoCard(),

                    const SizedBox(height: 24),

                    // 5. NÚT LÀM MỚI VỊ TRÍ (-1 LƯỢT CHECK)
                    ElevatedButton.icon(
                      onPressed: (_isQuotaExceeded || _isRefreshing) ? null : _fetchSnapshot,
                      icon: _isRefreshing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(
                        _isQuotaExceeded
                            ? 'ĐÃ HẾT 20 LƯỢT CHECK HÔM NAY'
                            : (_isRefreshing ? 'ĐANG LÀM MỚI...' : 'LÀM MỚI VỊ TRÍ (-1 LƯỢT CHECK)'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isQuotaExceeded ? Colors.grey : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),

                    const SizedBox(height: 12),
                    Text(
                      'Chính sách bảo mật GDPR: Mỗi lần bấm nút sẽ tiêu thụ 1 lượt kiểm tra để đảm bảo quyền riêng tư cho khách thuê.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildQuotaCard(int remaining, int totalAllowed, double progress) {
    Color barColor = AppColors.success;
    if (remaining <= 5) {
      barColor = AppColors.danger;
    } else if (remaining <= 10) {
      barColor = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: barColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.shield_outlined, color: barColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hạn ngạch kiểm tra riêng tư',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    Text(
                      'Còn $remaining / $totalAllowed lượt hôm nay',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: remaining == 0 ? AppColors.danger : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: barColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(color: barColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              )
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotaExceededWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_clock, color: AppColors.danger, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ĐÃ ĐẠT GIỚI HẠN KIỂM TRA TRONG NGÀY',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _errorMessage.isNotEmpty
                      ? _errorMessage
                      : 'Bạn đã sử dụng hết 20 lượt kiểm tra vị trí trong ngày hôm nay theo chính sách bảo mật quyền riêng tư của khách thuê. Lượt kiểm tra sẽ được cấp lại vào 00:00 ngày mai.',
                  style: TextStyle(color: Colors.red.shade900, fontSize: 13, height: 1.3),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSnapshotMapCard() {
    final lat = _snapshot?.latitude ?? 21.028511;
    final lng = _snapshot?.longitude ?? 105.854444;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        children: [
          // Banner cam kết bảo mật GDPR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: const Row(
              children: [
                Icon(Icons.privacy_tip_outlined, size: 16, color: Colors.deepOrange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bảo vệ riêng tư: TUYỆT ĐỐI KHÔNG lưu hay hiển thị đường đi (No Route)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Canvas vẽ duy nhất 1 Marker toạ độ Snapshot
          SizedBox(
            height: 240,
            width: double.infinity,
            child: ClipRRect(
              child: CustomPaint(
                painter: SnapshotMapPainter(latitude: lat, longitude: lng),
                child: Stack(
                  children: [
                    // Badge Snapshot góc trên
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.camera_alt_outlined, size: 14, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text(
                              'SNAPSHOT TỨC THỜI',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Toạ độ góc dưới
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleInfoCard() {
    final vehicleName = _snapshot?.vehicleName.isNotEmpty == true ? _snapshot!.vehicleName : 'Xe Cho Thuê';
    final speed = _snapshot?.speed ?? 0.0;
    final recordedAt = _snapshot?.recordedAt ?? 'Chưa cập nhật';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_car, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  vehicleName,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: speed > 5 ? Colors.green.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: speed > 5 ? AppColors.success : Colors.grey.shade400),
                ),
                child: Text(
                  speed > 5 ? 'Đang chạy' : 'Đang đỗ',
                  style: TextStyle(
                    color: speed > 5 ? AppColors.success : Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Vận tốc ghi nhận', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(
                      '${speed.toStringAsFixed(1)} km/h',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Thời điểm ghi nhận', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(
                      recordedAt,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

// Custom Painter cho bản đồ Snapshot: CHỈ HIỂN THỊ DUY NHẤT 1 MARKER (KHÔNG CÓ ROUTE)
class SnapshotMapPainter extends CustomPainter {
  final double latitude;
  final double longitude;

  SnapshotMapPainter({required this.latitude, required this.longitude});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Nền bản đồ phong cách radar bảo mật
    final bgPaint = Paint()..color = const Color(0xFFE5E9EC);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Lưới đường phố mờ
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    for (double y = 30; y < size.height; y += 45) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), roadPaint);
    }
    for (double x = 30; x < size.width; x += 55) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), roadPaint);
    }

    // 3. Tâm bản đồ đặt Marker tức thời (Snapshot Marker)
    final center = Offset(size.width / 2, size.height / 2);

    // Vòng tròn vùng bán kính an toàn (Safe Radius Area)
    final radiusPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.10)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 70, radiusPaint);

    final radiusBorder = Paint()
      ..color = AppColors.primary.withOpacity(0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, 70, radiusBorder);

    // Vòng radar nhấp nháy
    final radarPulse = Paint()
      ..color = AppColors.primary.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 30, radarPulse);

    // Marker trung tâm (Pin)
    final pinPaint = Paint()..color = AppColors.primary;
    canvas.drawCircle(center, 12, pinPaint);

    final whiteCenter = Paint()..color = Colors.white;
    canvas.drawCircle(center, 5, whiteCenter);
  }

  @override
  bool shouldRepaint(covariant SnapshotMapPainter oldDelegate) {
    return oldDelegate.latitude != latitude || oldDelegate.longitude != longitude;
  }
}
