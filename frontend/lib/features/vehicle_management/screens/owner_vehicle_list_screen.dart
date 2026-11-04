import 'package:flutter/material.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/vehicle_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/vehicle_service.dart';
import '../../auth/screens/login_screen.dart';
import 'add_vehicle_screen.dart';
import 'edit_vehicle_screen.dart';
import '../../booking/screens/booking_history_screen.dart';

class OwnerVehicleListScreen extends StatefulWidget {
  const OwnerVehicleListScreen({super.key});

  @override
  State<OwnerVehicleListScreen> createState() => _OwnerVehicleListScreenState();
}

class _OwnerVehicleListScreenState extends State<OwnerVehicleListScreen> {
  List<VehicleModel> _vehicles = [];
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    setState(() => _isLoading = true);
    final user = await AuthService.getCurrentUser();
    if (!mounted) return;

    if (user == null) {
      setState(() {
        _currentUser = null;
        _isLoading = false;
      });
      // Tự động chuyển tiếp sang màn hình đăng nhập / đăng ký
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng đăng nhập để quản lý xe của bạn!'),
              backgroundColor: AppColors.primary,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (ctx) => const LoginScreen()),
          );
        }
      });
      return;
    }

    _currentUser = user;
    final list = await VehicleService.getOwnerVehicles();
    if (!mounted) return;
    setState(() {
      _vehicles = list;
      _isLoading = false;
    });
  }

  void _navigateToAddVehicle() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để đăng xe mới!'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (ctx) => const LoginScreen()),
      ).then((_) => _fetchVehicles());
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (ctx) => const AddVehicleScreen()),
    );
    if (result == true) {
      _fetchVehicles();
    }
  }

  void _navigateToEditVehicle(VehicleModel vehicle) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (ctx) => EditVehicleScreen(vehicle: vehicle)),
    );
    if (result == true) {
      _fetchVehicles();
    }
  }

  void _confirmDeleteVehicle(VehicleModel vehicle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa xe'),
        content: Text('Bạn có chắc muốn xóa xe "${vehicle.name} (${vehicle.licensePlate})"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final res = await VehicleService.deleteVehicle(vehicle.id);
    if (!mounted) return;

    if (res['success'] == true) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Xóa xe thành công!'), backgroundColor: AppColors.success),
      );
      _fetchVehicles();
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Xóa xe thất bại'), backgroundColor: AppColors.danger),
      );
    }
  }

  void _handleApproveVehicle(VehicleModel vehicle) async {
    final res = await VehicleService.approveVehicle(vehicle.id);
    if (!mounted) return;

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã duyệt xe ${vehicle.name} thành công!'), backgroundColor: AppColors.success),
      );
      _fetchVehicles();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Lỗi khi duyệt xe'), backgroundColor: AppColors.danger),
      );
    }
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color text;
    String label;

    switch (status.toUpperCase()) {
      case 'PENDING_APPROVAL':
        bg = Colors.amber.shade100;
        text = Colors.brown.shade900;
        label = 'Chờ Admin duyệt';
        break;
      case 'AVAILABLE':
        bg = Colors.green.shade50;
        text = Colors.green.shade800;
        label = 'Đã duyệt (Sẵn sàng)';
        break;
      case 'REJECTED':
        bg = Colors.red.shade50;
        text = Colors.red.shade800;
        label = 'Bị từ chối';
        break;
      case 'RENTED':
      case 'ONGOING':
        bg = Colors.blue.shade50;
        text = Colors.blue.shade800;
        label = 'Đang có khách thuê';
        break;
      case 'MAINTENANCE':
        bg = Colors.grey.shade100;
        text = Colors.grey.shade700;
        label = 'Đang bảo dưỡng';
        break;
      default:
        bg = Colors.blue.shade50;
        text = Colors.blue.shade800;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: text.withAlpha(50)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: text),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_car_filled_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Chưa có xe nào được đăng',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hãy đăng tải chiếc xe đầu tiên của bạn để bắt đầu cho thuê và tạo thu nhập thụ động!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToAddVehicle,
              icon: const Icon(Icons.add),
              label: const Text('ĐĂNG XE NGAY'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnauthenticatedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_person_outlined, size: 72, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text(
              'Yêu Cầu Đăng Nhập',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bạn cần đăng nhập tài khoản để quản lý danh sách xe và đăng tải xe cho thuê.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (ctx) => const LoginScreen()),
                );
              },
              icon: const Icon(Icons.login),
              label: const Text('ĐĂNG NHẬP / ĐĂNG KÝ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget _buildPendingOrdersBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withAlpha(120), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.assignment_turned_in, color: AppColors.success, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yêu Cầu Thuê Xe Cần Duyệt',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 2),
                Text(
                  'Xem đơn khách đặt xe & duyệt đơn',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BookingHistoryScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Xem & Duyệt', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quản Lý Xe Của Tôi')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quản Lý Xe Của Tôi')),
        body: _buildUnauthenticatedState(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Xe Của Tôi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_turned_in_outlined),
            tooltip: 'Duyệt đơn thuê của khách',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BookingHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: _fetchVehicles,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchVehicles,
        child: _vehicles.isEmpty
            ? ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                children: [
                  _buildPendingOrdersBanner(),
                  _buildEmptyState(),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                itemCount: _vehicles.length + 1,
                itemBuilder: (ctx, index) {
                  if (index == 0) return _buildPendingOrdersBanner();
                  final v = _vehicles[index - 1];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ảnh thumbnail xe & Status Chip
                        Stack(
                          children: [
                            Image.network(
                              (v.thumbnailUrl != null && v.thumbnailUrl!.isNotEmpty)
                                  ? ApiEndpoints.resolveImageUrl(v.thumbnailUrl!)
                                  : 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341',
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Container(
                                height: 160,
                                color: Colors.grey.shade200,
                                child: const Center(child: Icon(Icons.directions_car, size: 54, color: Colors.grey)),
                              ),
                            ),
                            Positioned(
                              top: 10,
                              left: 10,
                              child: _buildStatusChip(v.status),
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(160),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  v.licensePlate,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Thông tin chi tiết xe
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      v.name,
                                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${CurrencyFormatter.format(v.basePricePerDay)}/ngày',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              // Thông số xe
                              Text(
                                '${v.brand} • ${v.seats} chỗ • ${v.transmission == 'AUTO' ? 'Tự động' : 'Số sàn'} • ${v.fuelType}',
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 8),

                              // Feature 1: Huy hiệu có tài xế (Nghiệp vụ cốt lõi của Người 1)
                              if (v.hasDriverOption)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.deepPurple.shade200),
                                  ),
                                  child: Text(
                                    '🚗 Có tài xế (+${CurrencyFormatter.format(v.driverFeePerDay)}/ngày)',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    '🚙 Chỉ cho thuê tự lái',
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 8),

                              // Nút hành động nhanh
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (v.status == 'PENDING_APPROVAL')
                                    TextButton.icon(
                                      onPressed: () => _handleApproveVehicle(v),
                                      icon: const Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
                                      label: const Text('Duyệt xe (Demo)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                    ),
                                  TextButton.icon(
                                    onPressed: () => _navigateToEditVehicle(v),
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    label: const Text('Chỉnh sửa'),
                                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () => _confirmDeleteVehicle(v),
                                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                                    label: const Text('Xóa', style: TextStyle(color: AppColors.danger)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddVehicle,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Đăng xe mới', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
