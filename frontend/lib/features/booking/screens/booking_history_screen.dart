import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/vehicle_image_helper.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/services/booking_service.dart';
import '../../gps_tracking/screens/renter_route_map_screen.dart';
import '../../inspection/screens/photo_inspection_screen.dart';
import '../../inspection/screens/comparison_screen.dart';
import 'checkout_payment_screen.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<BookingModel> _bookings = [];
  bool _isLoading = true;

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  final List<String> _tabs = [
    'Tất cả',
    'Chờ duyệt',
    'Đang đi',
    'Hoàn thành',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _fetchBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchBookings() async {
    setState(() => _isLoading = true);
    final list = await BookingService.getRenterBookings();
    if (!mounted) return;
    setState(() {
      _bookings = list;
      _isLoading = false;
    });
  }

  List<BookingModel> _getFilteredBookings(int tabIndex) {
    switch (tabIndex) {
      case 1: // Chờ duyệt
        return _bookings.where((b) => b.status.toUpperCase() == 'PENDING').toList();
      case 2: // Đang đi
        return _bookings
            .where((b) =>
                b.status.toUpperCase() == 'CONFIRMED' ||
                b.status.toUpperCase() == 'ONGOING')
            .toList();
      case 3: // Hoàn thành
        return _bookings.where((b) => b.status.toUpperCase() == 'COMPLETED').toList();
      case 0: // Tất cả
      default:
        return _bookings;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange.shade700;
      case 'CONFIRMED':
        return AppColors.primary;
      case 'ONGOING':
        return AppColors.success;
      case 'COMPLETED':
        return Colors.blueGrey;
      case 'CANCELLED':
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Chờ chủ xe duyệt';
      case 'CONFIRMED':
        return 'Đã duyệt & Đã cọc';
      case 'ONGOING':
        return 'Đang di chuyển';
      case 'COMPLETED':
        return 'Hoàn thành';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  Future<void> _handleStartTrip(int id) async {
    final ok = await BookingService.startTrip(id);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bắt đầu hành trình di chuyển!'), backgroundColor: AppColors.success),
      );
      _fetchBookings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể bắt đầu chuyến đi.'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _handleCompleteTrip(int id) async {
    final ok = await BookingService.completeBooking(id);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hoàn thành chuyến xe!'), backgroundColor: AppColors.success),
      );
      _fetchBookings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể hoàn tất chuyến xe.'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lịch Sử Chuyến Đi & Đơn Thuê'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: _tabs.map((title) => Tab(text: title)).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: List.generate(_tabs.length, (idx) {
                final filtered = _getFilteredBookings(idx);
                if (filtered.isEmpty) {
                  return _buildEmptyList(_tabs[idx]);
                }
                return RefreshIndicator(
                  onRefresh: _fetchBookings,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => _buildBookingCard(filtered[i]),
                  ),
                );
              }),
            ),
    );
  }

  Widget _buildEmptyList(String tabName) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_rounded, size: 54, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Không có chuyến đi ($tabName)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Khi bạn tạo đơn thuê xe, thông tin sẽ được cập nhật tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _fetchBookings,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Làm mới'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(BookingModel b) {
    final statusColor = _getStatusColor(b.status);
    final statusLabel = _getStatusLabel(b.status);
    final vehicle = b.vehicle;
    final thumbUrl = vehicle != null ? VehicleImageHelper.getThumbnail(vehicle) : null;

    final startStr = b.parsedStartDate != null ? _dateFormat.format(b.parsedStartDate!) : b.startDate;
    final endStr = b.parsedEndDate != null ? _dateFormat.format(b.parsedEndDate!) : b.endDate;

    final st = b.status.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: Mã đơn + Chip Trạng Thái
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        '#BK-${b.id}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: b.withDriver
                            ? AppColors.accent.withValues(alpha: 0.15)
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            b.withDriver ? Icons.person_rounded : Icons.directions_car_rounded,
                            size: 13,
                            color: b.withDriver ? AppColors.accent : AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            b.withDriver ? 'Có tài xế' : 'Tự lái',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: b.withDriver ? AppColors.accent : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Middle: Xe và Thời gian
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: thumbUrl != null
                      ? Image.network(
                          thumbUrl,
                          width: 85,
                          height: 65,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            width: 85,
                            height: 65,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.directions_car, color: Colors.grey),
                          ),
                        )
                      : Container(
                          width: 85,
                          height: 65,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.directions_car, color: Colors.grey),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle?.name ?? 'Xe ô tô',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (vehicle?.licensePlate != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Biển số: ${vehicle!.licensePlate}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.date_range_rounded, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '$startStr - $endStr (${b.rentalDays} ngày)',
                              style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Financial summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tổng chi phí:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Text(
                      CurrencyFormatter.format(b.totalPrice),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Tiền cọc (30%):', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Text(
                      CurrencyFormatter.format(b.depositAmount),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.danger),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action Buttons Row (Interactive Quick Actions)
            _buildActionButtons(b, st),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BookingModel b, String st) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // 1. Nút Lộ trình GPS
        OutlinedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RenterRouteMapScreen(bookingId: b.id)),
            );
          },
          icon: const Icon(Icons.map_rounded, size: 16),
          label: const Text('Lộ trình GPS', style: TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),

        // 2. Nút Biên bản nhận xe (Check-in)
        OutlinedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PhotoInspectionScreen(bookingId: b.id, stage: 'CHECK_IN'),
              ),
            ).then((_) => _fetchBookings());
          },
          icon: const Icon(Icons.camera_alt_outlined, size: 16),
          label: const Text('Check-in Nhận xe', style: TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryDark,
            side: const BorderSide(color: AppColors.primaryDark),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),

        // 3. Nút Biên bản trả xe (Check-out)
        OutlinedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PhotoInspectionScreen(bookingId: b.id, stage: 'CHECK_OUT'),
              ),
            ).then((_) => _fetchBookings());
          },
          icon: const Icon(Icons.assignment_turned_in_outlined, size: 16),
          label: const Text('Check-out Trả xe', style: TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.warning,
            side: const BorderSide(color: AppColors.warning),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),

        // 4. Nút Đối chiếu Before/After
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ComparisonScreen(bookingId: b.id)),
            ).then((_) => _fetchBookings());
          },
          icon: const Icon(Icons.compare_arrows_rounded, size: 16),
          label: const Text('Đối chiếu Before/After', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),

        // 5. Nút Khởi hành / Hoàn thành theo trạng thái
        if (st == 'CONFIRMED')
          ElevatedButton.icon(
            onPressed: () => _handleStartTrip(b.id),
            icon: const Icon(Icons.play_arrow_rounded, size: 16),
            label: const Text('Bắt đầu chuyến đi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),

        if (st == 'ONGOING')
          ElevatedButton.icon(
            onPressed: () => _handleCompleteTrip(b.id),
            icon: const Icon(Icons.flag_rounded, size: 16),
            label: const Text('Hoàn tất chuyến xe', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),

        if (st == 'PENDING')
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CheckoutPaymentScreen(booking: b)),
              ).then((_) => _fetchBookings());
            },
            icon: const Icon(Icons.payment_rounded, size: 16),
            label: const Text('Thanh toán cọc', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
      ],
    );
  }
}
