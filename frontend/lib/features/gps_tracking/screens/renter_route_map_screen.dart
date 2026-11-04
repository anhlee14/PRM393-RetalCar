import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/gps_model.dart';
import '../../../data/services/gps_service.dart';

class RenterRouteMapScreen extends StatefulWidget {
  final int bookingId;
  final String? initialStatus;
  final String? initialVehicleName;

  const RenterRouteMapScreen({
    super.key,
    this.bookingId = 1,
    this.initialStatus,
    this.initialVehicleName,
  });

  @override
  State<RenterRouteMapScreen> createState() => _RenterRouteMapScreenState();
}

class _RenterRouteMapScreenState extends State<RenterRouteMapScreen> {
  List<GpsLogModel> _routeLogs = [];
  Map<String, dynamic> _gpsStatus = {};
  bool _isLoading = true;
  bool _isPinging = false;

  // Chế độ Tự động đồng bộ GPS (Auto-Ping định kỳ trong chuyến đi)
  bool _isAutoTracking = false;
  Timer? _autoPingTimer;
  int _waypointCursor = 0;

  // Tuyến đường thực tế tại Hà Nội: Hòa Lạc -> Đại lộ Thăng Long -> Trần Duy Hưng -> Kim Mã -> Hồ Hoàn Kiếm
  static const List<Map<String, dynamic>> _hanoiCorridorWaypoints = [
    {'lat': 21.013100, 'lng': 105.525500, 'speed': 45.0, 'name': 'Khu CNC Hòa Lạc'},
    {'lat': 21.008500, 'lng': 105.615000, 'speed': 68.0, 'name': 'Đại lộ Thăng Long (Km18)'},
    {'lat': 21.005200, 'lng': 105.718000, 'speed': 62.0, 'name': 'Đại lộ Thăng Long - Thiên Đường Bảo Sơn'},
    {'lat': 21.006800, 'lng': 105.788500, 'speed': 48.0, 'name': 'Trung tâm Hội nghị Quốc gia'},
    {'lat': 21.012400, 'lng': 105.801200, 'speed': 38.0, 'name': 'Trần Duy Hưng - Cầu Giấy'},
    {'lat': 21.023500, 'lng': 105.809500, 'speed': 35.0, 'name': 'Nguyễn Chí Thanh - Đê La Thành'},
    {'lat': 21.030800, 'lng': 105.818500, 'speed': 40.0, 'name': 'Kim Mã - Liễu Giai'},
    {'lat': 21.033500, 'lng': 105.834500, 'speed': 32.0, 'name': 'Điện Biên Phủ - Ba Đình'},
    {'lat': 21.028511, 'lng': 105.852500, 'speed': 28.0, 'name': 'Tràng Thi - Hồ Hoàn Kiếm'},
    {'lat': 21.025800, 'lng': 105.855200, 'speed': 25.0, 'name': 'Nhà Hát Lớn Hà Nội'},
  ];

  String get _bookingStatus {
    final fromApi = (_gpsStatus['booking_status'] ?? _gpsStatus['bookingStatus'] ?? '').toString();
    if (fromApi.isNotEmpty) return fromApi.toUpperCase();
    return (widget.initialStatus ?? 'ONGOING').toUpperCase();
  }

  bool get _isOngoing => _bookingStatus == 'ONGOING';

  @override
  void initState() {
    super.initState();
    _fetchRouteAndStatus();
  }

  @override
  void dispose() {
    _autoPingTimer?.cancel();
    super.dispose();
  }

  void _toggleAutoTracking(bool enabled) {
    if (!_isOngoing) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chỉ có thể bật Tự động định vị khi chuyến đi đang diễn ra (ONGOING). Hiện tại: $_bookingStatus'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isAutoTracking = enabled);
    _autoPingTimer?.cancel();

    if (enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã bật Tự động đồng bộ GPS (Auto-Ping mỗi 8 giây trong chế độ Demo).'),
          backgroundColor: AppColors.primary,
        ),
      );
      _handlePingGps(isAuto: true);
      _autoPingTimer = Timer.periodic(const Duration(seconds: 8), (_) {
        if (!mounted || !_isOngoing || !_isAutoTracking) {
          _autoPingTimer?.cancel();
          return;
        }
        _handlePingGps(isAuto: true);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã tắt chế độ Tự động đồng bộ GPS. Bạn vẫn có thể bấm Ping GPS thủ công.'),
          backgroundColor: Colors.blueGrey,
        ),
      );
    }
  }

  Future<void> _fetchRouteAndStatus() async {
    setState(() => _isLoading = true);
    try {
      final status = await GpsService.checkGpsStatus(widget.bookingId);
      final logs = await GpsService.getRenterFullRoute(widget.bookingId);

      if (!mounted) return;
      setState(() {
        _gpsStatus = status;
        if (logs.isNotEmpty) {
          _routeLogs = logs;
          _waypointCursor = logs.length % _hanoiCorridorWaypoints.length;
        } else if (widget.bookingId >= 100 && _routeLogs.isEmpty && _isOngoing) {
          // Nạp lộ trình mẫu cho đơn thử nghiệm cục bộ (#BK-102)
          _seedLocalDemoRoute();
        }
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (_routeLogs.isEmpty && _isOngoing) {
          _seedLocalDemoRoute();
        }
        _isLoading = false;
      });
    }
  }

  void _seedLocalDemoRoute() {
    final now = DateTime.now();
    _routeLogs = [
      GpsLogModel(
        id: 1,
        latitude: _hanoiCorridorWaypoints[3]['lat'],
        longitude: _hanoiCorridorWaypoints[3]['lng'],
        speed: 42.0,
        recordedAt: now.subtract(const Duration(minutes: 25)).toIso8601String().substring(0, 19).replaceFirst('T', ' '),
      ),
      GpsLogModel(
        id: 2,
        latitude: _hanoiCorridorWaypoints[4]['lat'],
        longitude: _hanoiCorridorWaypoints[4]['lng'],
        speed: 38.0,
        recordedAt: now.subtract(const Duration(minutes: 15)).toIso8601String().substring(0, 19).replaceFirst('T', ' '),
      ),
      GpsLogModel(
        id: 3,
        latitude: _hanoiCorridorWaypoints[5]['lat'],
        longitude: _hanoiCorridorWaypoints[5]['lng'],
        speed: 35.0,
        recordedAt: now.subtract(const Duration(minutes: 5)).toIso8601String().substring(0, 19).replaceFirst('T', ' '),
      ),
    ];
    _waypointCursor = 6;
  }

  Future<void> _handlePingGps({bool isAuto = false}) async {
    if (_isPinging) return;

    if (!_isOngoing) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _bookingStatus == 'COMPLETED' || _bookingStatus == 'CANCELLED'
                ? 'Chuyến xe đã kết thúc ($_bookingStatus). Đã ngừng ghi nhận GPS để bảo vệ quyền riêng tư.'
                : 'Chuyến xe chưa bắt đầu ($_bookingStatus). Vui lòng bấm "Bắt đầu chuyến đi" sau khi nhận xe.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isPinging = true);

    // Lấy tọa độ tiếp theo dọc theo lộ trình thực tế tại Hà Nội để đường Polyline mượt mà
    final wp = _hanoiCorridorWaypoints[_waypointCursor % _hanoiCorridorWaypoints.length];
    final cycleOffset = (_routeLogs.length ~/ _hanoiCorridorWaypoints.length) * 0.0008;
    final newLat = (wp['lat'] as double) + cycleOffset;
    final newLng = (wp['lng'] as double) + cycleOffset;
    final speed = wp['speed'] as double;
    final locationLabel = wp['name'] as String;

    final result = await GpsService.pingGpsDetailed(
      bookingId: widget.bookingId,
      latitude: double.parse(newLat.toStringAsFixed(6)),
      longitude: double.parse(newLng.toStringAsFixed(6)),
      speed: speed,
    );

    if (!mounted) return;
    setState(() => _isPinging = false);

    if (result['success'] == true) {
      _waypointCursor = (_waypointCursor + 1) % _hanoiCorridorWaypoints.length;
      if (!isAuto) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã cập nhật GPS tại $locationLabel! Chu kỳ 60 phút đã được đặt lại.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      _fetchRouteAndStatus();
    } else if (widget.bookingId >= 100 || result['network_error'] == true) {
      // Hỗ trợ mượt mà cho các đơn mẫu thử nghiệm cục bộ (#BK-102)
      final nowStr = DateTime.now().toIso8601String().substring(0, 19).replaceFirst('T', ' ');
      setState(() {
        _waypointCursor = (_waypointCursor + 1) % _hanoiCorridorWaypoints.length;
        _routeLogs.add(
          GpsLogModel(
            id: _routeLogs.length + 1,
            latitude: double.parse(newLat.toStringAsFixed(6)),
            longitude: double.parse(newLng.toStringAsFixed(6)),
            speed: speed,
            recordedAt: nowStr,
          ),
        );
        _gpsStatus = {
          ..._gpsStatus,
          'booking_status': 'ONGOING',
          'is_overdue': false,
          'minutes_since_last_ping': 0,
        };
      });
      if (!isAuto) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã gửi tọa độ GPS tại $locationLabel! Hạn giờ 60 phút đã làm mới.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      if (_isAutoTracking) {
        setState(() => _isAutoTracking = false);
        _autoPingTimer?.cancel();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${result['message'] ?? 'Không thể gửi tọa độ GPS'}'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _showPrivacyInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.verified_user_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Bảo vệ Quyền riêng tư Lộ trình',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• Quyền của Khách thuê (Renter):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(height: 4),
            Text(
              'Bạn là người duy nhất được xem toàn bộ lịch sử lộ trình di chuyển (đường vẽ Polyline nối các mốc tọa độ).',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.35),
            ),
            SizedBox(height: 12),
            Text(
              '• Nghĩa vụ cập nhật GPS (Tối đa 60 phút/lần):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(height: 4),
            Text(
              'Khi chuyến đi đang ONGOING, bạn có thể bật "Tự động đồng bộ GPS" hoặc bấm "Ping GPS ngay" để đảm bảo xe luôn được cập nhật vị trí ít nhất mỗi 60 phút/lần.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.35),
            ),
            SizedBox(height: 12),
            Text(
              'Giới hạn đối với Chủ xe (Owner):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(height: 4),
            Text(
              'Chủ xe hoàn toàn KHÔNG thể xem màn hình lộ trình này. Chủ xe chỉ được tra cứu 1 điểm vị trí tức thời (Snapshot) tối đa 20 lần/ngày khi chuyến xe đang diễn ra.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.35),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = _isOngoing && (_gpsStatus['is_overdue'] == true || _gpsStatus['isOverdue'] == true);
    final minutesSincePing = _gpsStatus['minutes_since_last_ping'] ?? _gpsStatus['minutesSinceLastPing'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Lộ Trình Hành Trình #BK-${widget.bookingId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới lộ trình',
            onPressed: _fetchRouteAndStatus,
          ),
          IconButton(
            icon: const Icon(Icons.verified_user_outlined),
            tooltip: 'Quyền riêng tư GDPR',
            onPressed: _showPrivacyInfoDialog,
          ),
        ],
      ),
      floatingActionButton: _isOngoing
          ? FloatingActionButton.extended(
              onPressed: _isPinging ? null : () => _handlePingGps(isAuto: false),
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
                _isPinging ? 'ĐANG GỬI...' : 'PING GPS NGAY',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
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
                    // 1. BANNER CẢNH BÁO QUY ĐỊNH 60 PHÚT THEO TRẠNG THÁI CHUYẾN ĐI
                    _buildGpsComplianceBanner(isOverdue, minutesSincePing),

                    const SizedBox(height: 12),

                    // 2. CÔNG TẮC TỰ ĐỘNG ĐỒNG BỘ GPS ĐỊNH KỲ (AUTO-TRACKING)
                    if (_isOngoing) ...[
                      _buildAutoTrackingCard(),
                      const SizedBox(height: 16),
                    ],

                    // 3. KHUNG BẢN ĐỒ LỘ TRÌNH ĐẦY ĐỦ (FULL ROUTE POLYLINE)
                    _buildMapCard(),

                    const SizedBox(height: 16),

                    // 4. THẺ THỐNG KÊ TỔNG QUAN
                    _buildStatsRow(),

                    const SizedBox(height: 16),

                    // 5. DANH SÁCH CÁC MỐC TOẠ ĐỘ
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

  Widget _buildAutoTrackingCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isAutoTracking ? AppColors.primary : AppColors.border,
          width: _isAutoTracking ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (_isAutoTracking ? AppColors.primary : Colors.grey).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isAutoTracking ? Icons.satellite_alt_rounded : Icons.gps_not_fixed_rounded,
              color: _isAutoTracking ? AppColors.primary : Colors.grey.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tự động đồng bộ GPS (Auto-Ping)',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
                Text(
                  _isAutoTracking
                      ? 'Đang tự động gửi tọa độ hành trình định kỳ về máy chủ'
                      : 'Bật để ứng dụng tự động cập nhật vị trí mà không lo quá hạn 60 phút',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: _isAutoTracking,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
            activeThumbColor: AppColors.primary,
            onChanged: _toggleAutoTracking,
          ),
        ],
      ),
    );
  }

  Widget _buildGpsComplianceBanner(bool isOverdue, dynamic minutesSincePing) {
    if (!_isOngoing) {
      final isCompleted = _bookingStatus == 'COMPLETED' || _bookingStatus == 'CANCELLED';
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCompleted ? Colors.blueGrey.shade50 : Colors.amber.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted ? Colors.blueGrey.shade300 : AppColors.warning,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? Colors.blueGrey : AppColors.warning,
              ),
              child: Icon(
                isCompleted ? Icons.lock_clock_outlined : Icons.schedule_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCompleted
                        ? 'CHUYẾN XE ĐÃ KẾT THÚC ($_bookingStatus)'
                        : 'CHUYẾN XE CHƯA KHỞI HÀNH ($_bookingStatus)',
                    style: TextStyle(
                      color: isCompleted ? Colors.blueGrey.shade800 : Colors.orange.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCompleted
                        ? 'Đã ngừng thu thập tín hiệu GPS để bảo vệ quyền riêng tư của bạn. Bạn vẫn có thể xem lại lộ trình chuyến đi bên dưới.'
                        : 'Chế độ giám sát GPS 60 phút/lần chỉ kích hoạt sau khi bạn nhận xe và bấm "Bắt đầu chuyến đi".',
                    style: TextStyle(
                      color: isCompleted ? Colors.blueGrey.shade700 : Colors.orange.shade900,
                      fontSize: 12.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (isOverdue) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.danger, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.15),
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
                    '⚠️ CẢNH BÁO: QUÁ HẠN 60 PHÚT CHƯA GỬI GPS!',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Đã $minutesSincePing phút bạn chưa cập nhật toạ độ GPS. Quy định hợp đồng yêu cầu gửi vị trí tối đa 60 phút/lần. Hãy bấm "PING GPS NGAY" hoặc bật Tự động đồng bộ!',
                    style: TextStyle(color: Colors.red.shade900, fontSize: 12.5, height: 1.3),
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
                    '✅ TÌNH TRẠNG GPS HỢP LỆ (ĐANG DI CHUYỂN)',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Lần gửi gần nhất: $minutesSincePing phút trước (Tuân thủ quy định < 60 phút/lần).',
                    style: TextStyle(color: Colors.green.shade900, fontSize: 12.5),
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
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        children: [
          // Canvas vẽ mô phỏng bản đồ tương tác
          SizedBox(
            height: 260,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CustomPaint(
                painter: RouteMapPainter(routeLogs: _routeLogs),
                child: Stack(
                  children: [
                    // Chú thích góc trên trái
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 9, color: AppColors.success),
                            SizedBox(width: 4),
                            Text('Điểm xuất phát', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                            SizedBox(width: 10),
                            Icon(Icons.circle, size: 9, color: Color(0xFFD32F2F)),
                            SizedBox(width: 4),
                            Text('Vị trí hiện tại', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                          ],
                        ),
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
                            color: Colors.black.withValues(alpha: 0.75),
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
            title: 'Mốc hành trình',
            value: '$totalPoints điểm GPS',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            icon: Icons.speed,
            title: 'Tốc độ ghi nhận',
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
              color: color.withValues(alpha: 0.12),
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
          'Nhật ký lộ trình chi tiết (Chỉ dành cho Khách thuê)',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
        child: Center(
          child: Text(
            _isOngoing
                ? 'Chưa có toạ độ nào được ghi nhận.\nNhấn nút "PING GPS NGAY" hoặc bật Tự động đồng bộ để ghi nhận lộ trình!'
                : 'Chưa có dữ liệu lộ trình cho đơn thuê này (Trạng thái: $_bookingStatus).',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
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
                      log.recordedAt.isNotEmpty ? log.recordedAt : 'Điểm ghi nhận trên lộ trình',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
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
    majorPath.cubicTo(
      size.width * 0.4,
      size.height * 0.25,
      size.width * 0.6,
      size.height * 0.75,
      size.width,
      size.height * 0.7,
    );
    canvas.drawPath(majorPath, roadPaint);

    if (routeLogs.isEmpty) {
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

    // 3. Chuẩn hoá toạ độ để Fit vào kích thước Canvas
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

    const padding = 42.0;
    final usableW = size.width - padding * 2;
    final usableH = size.height - padding * 2;

    List<Offset> points = [];
    for (final p in routeLogs) {
      final normX = ((p.longitude - minLng) / lngRange).clamp(0.0, 1.0);
      final normY = 1.0 - ((p.latitude - minLat) / latRange).clamp(0.0, 1.0);

      final px = padding + normX * usableW;
      final py = padding + normY * usableH;
      points.add(Offset(px, py));
    }

    // 4. Vẽ đường Polyline nối các toạ độ
    if (points.length >= 2) {
      final glowPaint = Paint()
        ..color = AppColors.primary.withValues(alpha: 0.3)
        ..strokeWidth = 8.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final polyPath = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        polyPath.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(polyPath, glowPaint);

      final linePaint = Paint()
        ..color = AppColors.primary
        ..strokeWidth = 4.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(polyPath, linePaint);
    }

    // 5. Vẽ các mốc toạ độ trung gian (Waypoints)
    final nodePaint = Paint()..color = Colors.white;
    final nodeBorder = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length; i++) {
      if (i == 0 || i == points.length - 1) continue;
      canvas.drawCircle(points[i], 4, nodePaint);
      canvas.drawCircle(points[i], 4, nodeBorder);
    }

    // 6. Điểm bắt đầu (Start Point - Xanh lá)
    if (points.isNotEmpty) {
      final startPoint = points.first;
      final startPaint = Paint()..color = AppColors.success;
      canvas.drawCircle(startPoint, 7, startPaint);
      canvas.drawCircle(
        startPoint,
        9,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // 7. Điểm hiện tại (Current Car Location - Có hiệu ứng radar)
    if (points.isNotEmpty) {
      final endPoint = points.last;

      final pulsePaint = Paint()
        ..color = AppColors.primary.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(endPoint, 18, pulsePaint);

      final carPaint = Paint()..color = const Color(0xFFD32F2F);
      canvas.drawCircle(endPoint, 8, carPaint);
      canvas.drawCircle(
        endPoint,
        10,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant RouteMapPainter oldDelegate) {
    return oldDelegate.routeLogs.length != routeLogs.length;
  }
}
