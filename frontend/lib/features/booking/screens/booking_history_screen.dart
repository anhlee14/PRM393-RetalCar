import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/vehicle_image_helper.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/models/vehicle_model.dart';
import '../../../data/services/booking_service.dart';
import '../../gps_tracking/screens/renter_route_map_screen.dart';
import '../../inspection/screens/photo_inspection_screen.dart';
import '../../inspection/screens/comparison_screen.dart';
import 'checkout_payment_screen.dart';
import '../../inspection/screens/checkin_review_screen.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<BookingModel> _bookings = [];
  bool _isLoading = true;
  UserModel? _currentUser;
  Set<int> _paidDepositBookingIds = {};
  bool get _isOwner => _currentUser?.role == 'ROLE_OWNER';

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  final List<String> _tabs = [
    'Tất cả',
    'Chờ duyệt',
    'Đang đi',
    'Hoàn thành',
  ];

  void _loadMockBookings() {
    setState(() {
      _bookings = [
        BookingModel(
          id: 101,
          startDate: DateTime.now().add(const Duration(days: 1)).toIso8601String(),
          endDate: DateTime.now().add(const Duration(days: 3)).toIso8601String(),
          withDriver: true,
          carRentalPrice: 2400000,
          driverServicePrice: 900000,
          totalPrice: 3300000,
          depositAmount: 990000,
          status: 'CONFIRMED',
          pickupAddress: 'FPT University, Khu CNC Hòa Lạc, Hà Nội',
          returnAddress: 'FPT University, Khu CNC Hòa Lạc, Hà Nội',
          vehicle: VehicleModel(
            id: 1,
            name: 'VinFast VF8 Plus 2024',
            brand: 'VinFast',
            modelYear: 2024,
            licensePlate: '30K-888.99',
            vehicleType: 'SUV',
            transmission: 'Tự động',
            fuelType: 'Điện',
            basePricePerDay: 1200000,
            hasDriverOption: true,
            driverFeePerDay: 450000,
            seats: 5,
            status: 'AVAILABLE',
            thumbnailUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/2022_Vinfast_VF8_front_view.jpg/1280px-2022_Vinfast_VF8_front_view.jpg',
          ),
        ),
        BookingModel(
          id: 102,
          startDate: DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
          endDate: DateTime.now().add(const Duration(days: 2)).toIso8601String(),
          withDriver: false,
          carRentalPrice: 1800000,
          driverServicePrice: 0,
          totalPrice: 1800000,
          depositAmount: 540000,
          status: 'ONGOING',
          pickupAddress: 'Cầu Giấy, Hà Nội',
          returnAddress: 'Cầu Giấy, Hà Nội',
          vehicle: VehicleModel(
            id: 2,
            name: 'Mazda CX-5 2.0 Premium',
            brand: 'Mazda',
            modelYear: 2023,
            licensePlate: '30H-678.90',
            vehicleType: 'SUV',
            transmission: 'Tự động',
            fuelType: 'Xăng',
            basePricePerDay: 900000,
            hasDriverOption: true,
            driverFeePerDay: 400000,
            seats: 5,
            status: 'RENTED',
            thumbnailUrl: 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341',
          ),
        ),
        BookingModel(
          id: 103,
          startDate: DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
          endDate: DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
          withDriver: true,
          carRentalPrice: 2200000,
          driverServicePrice: 800000,
          totalPrice: 3000000,
          depositAmount: 900000,
          status: 'COMPLETED',
          pickupAddress: 'Sân bay Nội Bài, Hà Nội',
          returnAddress: 'Hoàn Kiếm, Hà Nội',
          vehicle: VehicleModel(
            id: 3,
            name: 'Toyota Camry 2.5Q 2023',
            brand: 'Toyota',
            modelYear: 2023,
            licensePlate: '29A-999.88',
            vehicleType: 'SEDAN',
            transmission: 'Tự động',
            fuelType: 'Xăng',
            basePricePerDay: 1100000,
            hasDriverOption: true,
            driverFeePerDay: 400000,
            seats: 5,
            status: 'AVAILABLE',
            thumbnailUrl: 'https://images.unsplash.com/photo-1621007947382-bb3c3994e3fb',
          ),
        ),
        BookingModel(
          id: 104,
          startDate: DateTime.now().add(const Duration(days: 5)).toIso8601String(),
          endDate: DateTime.now().add(const Duration(days: 7)).toIso8601String(),
          withDriver: false,
          carRentalPrice: 1600000,
          driverServicePrice: 0,
          totalPrice: 1600000,
          depositAmount: 480000,
          status: 'PENDING',
          pickupAddress: 'Hà Đông, Hà Nội',
          returnAddress: 'Hà Đông, Hà Nội',
          vehicle: VehicleModel(
            id: 4,
            name: 'Honda CR-V L 2023',
            brand: 'Honda',
            modelYear: 2023,
            licensePlate: '30E-123.45',
            vehicleType: 'SUV',
            transmission: 'Tự động',
            fuelType: 'Xăng',
            basePricePerDay: 800000,
            hasDriverOption: false,
            driverFeePerDay: 0,
            seats: 7,
            status: 'AVAILABLE',
            thumbnailUrl: 'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf',
          ),
        ),
      ];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã nạp 4 chuyến xe mẫu để bạn kiểm thử đầy đủ các trạng thái!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

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
    final user = await AuthService.getCurrentUser();
    List<BookingModel> list = [];
    if (user != null && user.role == 'ROLE_OWNER') {
      list = await BookingService.getOwnerBookings();
      if (list.isEmpty) {
        final renterList = await BookingService.getRenterBookings();
        if (renterList.isNotEmpty) list = renterList;
      }
    } else {
      list = await BookingService.getRenterBookings();
      if (list.isEmpty) {
        final ownerList = await BookingService.getOwnerBookings();
        if (ownerList.isNotEmpty) list = ownerList;
      }
    }
    Set<int> localPaidSet = {};
    try {
      final prefs = await SharedPreferences.getInstance();
      final paidList = prefs.getStringList('paid_deposit_bookings') ?? [];
      localPaidSet = paidList.map((e) => int.tryParse(e) ?? 0).where((id) => id > 0).toSet();
    } catch (_) {}

    for (var b in list) {
      if (b.status == 'CONFIRMED' || b.status == 'ONGOING' || b.status == 'COMPLETED') {
        localPaidSet.add(b.id);
      }
    }

    if (!mounted) return;
    setState(() {
      _currentUser = user;
      _bookings = list;
      _paidDepositBookingIds = localPaidSet;
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

  Future<void> _handleConfirmBooking(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.success),
            SizedBox(width: 8),
            Text('Duyệt Đơn Thuê Xe', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Bạn với vai trò Chủ xe có chắc chắn muốn duyệt đơn thuê #BK-$id này không?\n\nSau khi duyệt, trạng thái chuyến xe sẽ chuyển thành Đã duyệt (CONFIRMED).',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận duyệt'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    final ok = await BookingService.confirmBooking(id);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chủ xe đã duyệt đơn thuê #BK-$id thành công! Chuyển sang trạng thái Đã duyệt.'),
          backgroundColor: AppColors.success,
        ),
      );
      _fetchBookings();
    } else {
      // Fallback cục bộ cho chế độ kiểm thử
      setState(() {
        _bookings = _bookings.map((b) {
          if (b.id == id) {
            return BookingModel(
              id: b.id,
              renter: b.renter,
              vehicle: b.vehicle,
              startDate: b.startDate,
              endDate: b.endDate,
              withDriver: b.withDriver,
              carRentalPrice: b.carRentalPrice,
              driverServicePrice: b.driverServicePrice,
              totalPrice: b.totalPrice,
              depositAmount: b.depositAmount,
              status: 'CONFIRMED',
              pickupAddress: b.pickupAddress,
              returnAddress: b.returnAddress,
              lastRenterGpsPing: b.lastRenterGpsPing,
            );
          }
          return b;
        }).toList();
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã duyệt đơn thuê #BK-$id thành công (Chế độ Thử nghiệm)!'),
          backgroundColor: AppColors.success,
        ),
      );
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
      // Fallback cục bộ cho chế độ kiểm thử
      setState(() {
        _bookings = _bookings.map((b) {
          if (b.id == id) {
            return BookingModel(
              id: b.id,
              renter: b.renter,
              vehicle: b.vehicle,
              startDate: b.startDate,
              endDate: b.endDate,
              withDriver: b.withDriver,
              carRentalPrice: b.carRentalPrice,
              driverServicePrice: b.driverServicePrice,
              totalPrice: b.totalPrice,
              depositAmount: b.depositAmount,
              status: 'ONGOING',
              pickupAddress: b.pickupAddress,
              returnAddress: b.returnAddress,
              lastRenterGpsPing: b.lastRenterGpsPing,
            );
          }
          return b;
        }).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bắt đầu hành trình di chuyển (Chế độ Thử nghiệm)!'),
          backgroundColor: AppColors.success,
        ),
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
      // Fallback cục bộ cho chế độ kiểm thử
      setState(() {
        _bookings = _bookings.map((b) {
          if (b.id == id) {
            return BookingModel(
              id: b.id,
              renter: b.renter,
              vehicle: b.vehicle,
              startDate: b.startDate,
              endDate: b.endDate,
              withDriver: b.withDriver,
              carRentalPrice: b.carRentalPrice,
              driverServicePrice: b.driverServicePrice,
              totalPrice: b.totalPrice,
              depositAmount: b.depositAmount,
              status: 'COMPLETED',
              pickupAddress: b.pickupAddress,
              returnAddress: b.returnAddress,
              lastRenterGpsPing: b.lastRenterGpsPing,
            );
          }
          return b;
        }).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã hoàn tất chuyến xe (Chế độ Thử nghiệm)!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isOwner ? 'Quản Lý Đơn Thuê (Chủ Xe)' : 'Lịch Sử Chuyến Đi & Đơn Thuê'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Nạp dữ liệu mẫu thử nghiệm',
            onPressed: _loadMockBookings,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới từ máy chủ',
            onPressed: _fetchBookings,
          ),
        ],
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _fetchBookings,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Làm mới'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _loadMockBookings,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Nạp dữ liệu mẫu'),
                ),
              ],
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
    final isRenterOfBooking = b.renter != null && _currentUser != null && b.renter!.id == _currentUser!.id;
    final canApproveBooking = _isOwner && !isRenterOfBooking;
    final isDepositPaid = _paidDepositBookingIds.contains(b.id);

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

        // 2. Check-in:
        // CHỦ XE: "Check-in Giao xe" (chủ xe up ảnh, ODO, xăng ban đầu và đẩy lên cho khách thuê xem)
        if (canApproveBooking && (st == 'CONFIRMED' || st == 'PENDING' || st == 'ONGOING'))
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PhotoInspectionScreen(
                    bookingId: b.id,
                    stage: 'CHECK_IN',
                    isOwner: true,
                    title: 'BIÊN BẢN GIAO XE (CHỦ XE CHECK-IN)',
                    submitButtonText: 'GỬI BIÊN BẢN GIAO XE CHO KHÁCH',
                  ),
                ),
              ).then((_) => _fetchBookings());
            },
            icon: const Icon(Icons.car_rental_rounded, size: 16),
            label: const Text('Check-in Giao xe', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
              side: const BorderSide(color: AppColors.primaryDark),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),

        // NGƯỜI THUÊ: "Xác nhận nhận xe" (người thuê xem biên bản bàn giao của chủ xe và xác nhận)
        if (!canApproveBooking && (st == 'CONFIRMED' || st == 'ONGOING'))
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CheckInReviewScreen(bookingId: b.id),
                ),
              ).then((_) => _fetchBookings());
            },
            icon: const Icon(Icons.assignment_turned_in_rounded, size: 16),
            label: const Text('Xác nhận nhận xe', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),

        // 3. Check-out:
        // NGƯỜI THUÊ: "Check-out Trả xe" (người thuê up thông tin, ảnh ODO, xăng lúc trả xe lên)
        if (!canApproveBooking && st == 'ONGOING')
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PhotoInspectionScreen(
                    bookingId: b.id,
                    stage: 'CHECK_OUT',
                    isOwner: false,
                    title: 'BIÊN BẢN TRẢ XE (NGƯỜI THUÊ CHECK-OUT)',
                    submitButtonText: 'GỬI BIÊN BẢN TRẢ XE CHO CHỦ XE',
                  ),
                ),
              ).then((_) => _fetchBookings());
            },
            icon: const Icon(Icons.camera_alt_outlined, size: 16),
            label: const Text('Check-out Trả xe', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.warning,
              side: const BorderSide(color: AppColors.warning),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),

        // CHỦ XE: "Duyệt biên bản trả xe" (chủ xe xem thông tin khách up lên và duyệt)
        if (canApproveBooking && (st == 'ONGOING' || st == 'COMPLETED'))
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ComparisonScreen(bookingId: b.id)),
              ).then((_) => _fetchBookings());
            },
            icon: const Icon(Icons.fact_check_rounded, size: 16),
            label: const Text('Duyệt biên bản trả xe', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),

        // 4. Nút Đối chiếu Before/After (hiển thị khi chuyến xe hoàn thành để cả 2 bên cùng xem lại)
        if (st == 'COMPLETED')
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

        if (st == 'PENDING' && canApproveBooking)
          ElevatedButton.icon(
            onPressed: () => _handleConfirmBooking(b.id),
            icon: const Icon(Icons.check_circle_outline, size: 16),
            label: const Text('Duyệt đơn thuê', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        if (st == 'PENDING' && !canApproveBooking)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.hourglass_top_rounded, size: 14, color: Colors.orange.shade800),
                const SizedBox(width: 6),
                Text(
                  'Chờ chủ xe duyệt đơn',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                ),
              ],
            ),
          ),
        if (st == 'PENDING' && !canApproveBooking)
          isDepositPaid
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                      const SizedBox(width: 6),
                      Text(
                        'Đã thanh toán cọc',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success),
                      ),
                    ],
                  ),
                )
              : OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CheckoutPaymentScreen(booking: b)),
                    ).then((_) => _fetchBookings());
                  },
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                  label: const Text('Thanh toán cọc', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
        if (canApproveBooking && isDepositPaid && st == 'PENDING')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, size: 13, color: AppColors.success),
                const SizedBox(width: 4),
                Text(
                  'Khách đã nộp cọc',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
