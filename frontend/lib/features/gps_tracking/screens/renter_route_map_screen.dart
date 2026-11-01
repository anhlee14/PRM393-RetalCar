import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/gps_model.dart';
import '../../../data/services/gps_service.dart';
import 'owner_snapshot_screen.dart';

class RenterRouteMapScreen extends StatefulWidget {
  final int bookingId;
  const RenterRouteMapScreen({super.key, this.bookingId = 1});

  @override
  State<RenterRouteMapScreen> createState() => _RenterRouteMapScreenState();
}

class _RenterRouteMapScreenState extends State<RenterRouteMapScreen> {
  List<GpsLogModel> _routeLogs = [];
  Map<String, dynamic> _gpsStatus = {};
  bool _isLoading = true;
  bool _isPinging = false;

  @override
  void initState() {
    super.initState();
    _fetchRouteAndStatus();
  }

  Future<void> _fetchRouteAndStatus() async {
    setState(() => _isLoading = true);
    final status = await GpsService.checkGpsStatus(widget.bookingId);
    final logs = await GpsService.getRenterFullRoute(widget.bookingId);

    if (mounted) {
      setState(() {
        _gpsStatus = status;
        _routeLogs = logs;
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePingGps() async {
    setState(() => _isPinging = true);

    // Tính toạ độ mới (mô phỏng lộ trình xe đang di chuyển tại Hà Nội / TP.HCM)
    double baseLat = 21.028511;
    double baseLng = 105.854444;

    if (_routeLogs.isNotEmpty) {
      baseLat = _routeLogs.last.latitude;
      baseLng = _routeLogs.last.longitude;
    }

    final random = Random();
    final newLat = baseLat + (random.nextDouble() - 0.5) * 0.008;
    final newLng = baseLng + (random.nextDouble() - 0.5) * 0.008;
    final speed = 35.0 + random.nextInt(25);

    final success = await GpsService.pingGps(
      bookingId: widget.bookingId,
      latitude: double.parse(newLat.toStringAsFixed(6)),
      longitude: double.parse(newLng.toStringAsFixed(6)),
      speed: speed.toDouble(),
    );

    if (mounted) {
      setState(() => _isPinging = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Gửi vị trí GPS thành công! Hạn giờ 60 phút đã được làm mới.'),
            backgroundColor: AppColors.success,
          ),
        );
        _fetchRouteAndStatus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Không thể gửi toạ độ GPS. Vui lòng thử lại!'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = _gpsStatus['is_overdue'] == true;
    final minutesSincePing = _gpsStatus['minutes_since_last_ping'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Lộ Trình Xe #${widget.bookingId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: _fetchRouteAndStatus,
          ),
          IconButton(
            icon: const Icon(Icons.shield_outlined),
            tooltip: 'Xem giao diện Chủ xe',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OwnerSnapshotScreen(bookingId: widget.bookingId),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isPinging ? null : _handlePingGps,
        backgroundColor: isOverdue ? AppColors.danger : AppColors.primary,
        foregroundColor: Colors.white,
        icon: _isPinging
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.my_location),
        label: Text(
          _isPinging ? 'ĐANG GỬI...' : 'PING GPS (GỬI VỊ TRÍ)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchRouteAndStatus,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. BANNER CẢNH BÁO QUY ĐỊNH 1 TIẾNG
                    _buildGpsComplianceBanner(isOverdue, minutesSincePing),

                    const SizedBox(height: 16),

                    // 2. KHUNG BẢN ĐỒ LỘ TRÌNH ĐẦY ĐỦ (FULL ROUTE)
                    _buildMapCard(),

                    const SizedBox(height: 16),

                    // 3. THẺ THỐNG KÊ TỔNG QUAN
                    _buildStatsRow(),

                    const SizedBox(height: 16),

                    // 4. DANH SÁCH CÁC MỐC TOẠ ĐỘ
                    _buildLogsHeader(),
                    const SizedBox(height: 8),
                    _buildLogsList(),

                    const SizedBox(height: 80), // Chừa khoảng trống cho FAB
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildGpsComplianceBanner(bool isOverdue, dynamic minutesSincePing) {
    if (isOverdue) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.danger, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.danger,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚠️ CẢNH BÁO: QUÁ HẠN GỬI GPS!',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Đã $minutesSincePing phút bạn chưa cập nhật toạ độ GPS. Quy định hợp đồng yêu cầu gửi vị trí tối thiểu 60 phút/lần để tránh bị phạt vi phạm hợp đồng.',
                    style: TextStyle(color: Colors.red.shade900, fontSize: 13, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success,
              ),
              child: const Icon(Icons.check_circle_outline, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✅ TÌNH TRẠNG GPS HỢP LỆ',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Lần gửi gần nhất: $minutesSincePing phút trước (Quy định: < 60 phút/lần).',
                    style: TextStyle(color: Colors.green.shade900, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildMapCard() {
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
          // Banner quyền riêng tư
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Quyền riêng tư: Chỉ khách thuê mới xem được toàn bộ lộ trình này',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'FULL ROUTE',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Canvas vẽ mô phỏng bản đồ tương tác
          SizedBox(
            height: 260,
            width: double.infinity,
            child: ClipRRect(
              child: CustomPaint(
                painter: RouteMapPainter(routeLogs: _routeLogs),
                child: Stack(
                  children: [
                    // Nút Reset view góc phải
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4),
                          ],
                        ),
                        child: const Icon(Icons.layers, size: 18, color: AppColors.primary),
                      ),
                    ),
                    // Nhãn vị trí hiện tại góc dưới
                    if (_routeLogs.isNotEmpty)
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.navigation, color: Colors.amber, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                '${_routeLogs.last.speed.toStringAsFixed(1)} km/h • ${_routeLogs.last.latitude.toStringAsFixed(4)}, ${_routeLogs.last.longitude.toStringAsFixed(4)}',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
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

  Widget _buildStatsRow() {
    final totalPoints = _routeLogs.length;
    final latestSpeed = _routeLogs.isNotEmpty ? _routeLogs.last.speed : 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            icon: Icons.alt_route,
            title: 'Mốc toạ độ',
            value: '$totalPoints điểm',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            icon: Icons.speed,
            title: 'Tốc độ hiện tại',
            value: '${latestSpeed.toStringAsFixed(1)} km/h',
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLogsHeader() {
    return const Row(
      children: [
        Icon(Icons.history, size: 20, color: AppColors.primary),
        SizedBox(width: 8),
        Text(
          'Lịch sử mốc toạ độ (GPS Logs)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildLogsList() {
    if (_routeLogs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text(
            'Chưa có toạ độ nào được ghi nhận.\nNhấn nút "PING GPS" bên dưới để gửi toạ độ đầu tiên!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final reversedLogs = _routeLogs.reversed.toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reversedLogs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final log = reversedLogs[index];
        final isLatest = index == 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isLatest ? AppColors.primary.withValues(alpha: 0.04) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isLatest ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLatest ? AppColors.primary : Colors.grey.shade200,
                ),
                child: Center(
                  child: Text(
                    '${reversedLogs.length - index}',
                    style: TextStyle(
                      color: isLatest ? Colors.white : Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Toạ độ: ${log.latitude.toStringAsFixed(6)}, ${log.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      log.recordedAt,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${log.speed.toStringAsFixed(0)} km/h',
                  style: const TextStyle(color: Colors.deepOrange, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Custom Painter vẽ bản đồ đường sá và lộ trình polyline
class RouteMapPainter extends CustomPainter {
  final List<GpsLogModel> routeLogs;
  RouteMapPainter({required this.routeLogs});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Nền bản đồ (Map Background)
    final bgPaint = Paint()..color = const Color(0xFFE8ECEF);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Vẽ lưới đường sá phong cách bản đồ số (Street Grid)
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;

    final minorRoadPaint = Paint()
      ..color = const Color(0xFFD6DBDF)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Đường ngang & dọc mô phỏng mạng lưới phố
    for (double y = 40; y < size.height; y += 50) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), minorRoadPaint);
    }
    for (double x = 40; x < size.width; x += 60) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), minorRoadPaint);
    }
    // Đường đại lộ chính (Major arterial road)
    final majorPath = Path();
    majorPath.moveTo(0, size.height * 0.3);
    majorPath.cubicTo(size.width * 0.4, size.height * 0.25, size.width * 0.6, size.height * 0.75, size.width, size.height * 0.7);
    canvas.drawPath(majorPath, roadPaint);

    if (routeLogs.isEmpty) {
      // Nếu chưa có toạ độ, vẽ điểm chờ
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'Chưa có toạ độ lộ trình',
          style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2),
      );
      return;
    }

    // 3. Chuẩn hoá toạ độ to Fit vào kích thước Canvas
    double minLat = routeLogs.first.latitude;
    double maxLat = routeLogs.first.latitude;
    double minLng = routeLogs.first.longitude;
    double maxLng = routeLogs.first.longitude;

    for (final p in routeLogs) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final latRange = (maxLat - minLat).abs() < 0.0001 ? 0.002 : (maxLat - minLat);
    final lngRange = (maxLng - minLng).abs() < 0.0001 ? 0.002 : (maxLng - minLng);

    const padding = 40.0;
    final usableW = size.width - padding * 2;
    final usableH = size.height - padding * 2;

    List<Offset> points = [];
    for (final p in routeLogs) {
      final normX = ((p.longitude - minLng) / lngRange).clamp(0.0, 1.0);
      final normY = 1.0 - ((p.latitude - minLat) / latRange).clamp(0.0, 1.0); // đảo trục Y

      final px = padding + normX * usableW;
      final py = padding + normY * usableH;
      points.add(Offset(px, py));
    }

    // 4. Vẽ đường Polyline nối các toạ độ
    if (points.length >= 2) {
      // Glow viền ngoài
      final glowPaint = Paint()
        ..color = AppColors.primary.withOpacity(0.3)
        ..strokeWidth = 8.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final polyPath = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        polyPath.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(polyPath, glowPaint);

      // Đường chính màu xanh đậm
      final linePaint = Paint()
        ..color = AppColors.primary
        ..strokeWidth = 4.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(polyPath, linePaint);
    }

    // 5. Vẽ các mốc toạ độ (Waypoints)
    final nodePaint = Paint()..color = Colors.white;
    final nodeBorder = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length; i++) {
      if (i == 0 || i == points.length - 1) continue; // bỏ qua điểm đầu và cuối
      canvas.drawCircle(points[i], 4, nodePaint);
      canvas.drawCircle(points[i], 4, nodeBorder);
    }

    // 6. Điểm bắt đầu (Start Point - Xanh lá)
    if (points.isNotEmpty) {
      final startPoint = points.first;
      final startPaint = Paint()..color = AppColors.success;
      canvas.drawCircle(startPoint, 7, startPaint);
      canvas.drawCircle(startPoint, 9, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);
    }

    // 7. Điểm hiện tại (Current Car Location - Có hiệu ứng radar)
    if (points.isNotEmpty) {
      final endPoint = points.last;

      // Radar Pulse
      final pulsePaint = Paint()
        ..color = AppColors.primary.withOpacity(0.25)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(endPoint, 18, pulsePaint);

      // Pin tâm
      final carPaint = Paint()..color = const Color(0xFFD32F2F);
      canvas.drawCircle(endPoint, 8, carPaint);
      canvas.drawCircle(endPoint, 10, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2.5);
    }
  }

  @override
  bool shouldRepaint(covariant RouteMapPainter oldDelegate) {
    return oldDelegate.routeLogs.length != routeLogs.length;
  }
}
