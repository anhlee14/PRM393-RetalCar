import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/vehicle_model.dart';
import '../../../data/services/vehicle_service.dart';

class AdminVehicleApprovalScreen extends StatefulWidget {
  const AdminVehicleApprovalScreen({super.key});

  @override
  State<AdminVehicleApprovalScreen> createState() => _AdminVehicleApprovalScreenState();
}

class _AdminVehicleApprovalScreenState extends State<AdminVehicleApprovalScreen> {
  List<VehicleModel> _pendingVehicles = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPendingVehicles();
  }

  Future<void> _fetchPendingVehicles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await VehicleService.getPendingVehicles();
      if (!mounted) return;
      setState(() {
        _pendingVehicles = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể tải danh sách xe chờ duyệt: $e';
        _isLoading = false;
      });
    }
  }

  void _handleApprove(VehicleModel vehicle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Xác nhận duyệt xe'),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn duyệt xe "${vehicle.name}" (${vehicle.licensePlate}) cho thuê không?\nXe sẽ được hiển thị công khai trên ứng dụng ngay sau khi duyệt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final res = await VehicleService.approveVehicle(vehicle.id);
              if (!mounted) return;

              if (res['success'] == true) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Đã duyệt xe ${vehicle.name} thành công!'),
                    backgroundColor: AppColors.success,
                  ),
                );
                _fetchPendingVehicles();
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(res['message'] ?? 'Lỗi khi duyệt xe'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            child: const Text('Đồng ý duyệt'),
          ),
        ],
      ),
    );
  }

  void _handleReject(VehicleModel vehicle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 8),
            Text('Từ chối duyệt xe'),
          ],
        ),
        content: Text(
          'Bạn có chắc muốn từ chối phê duyệt xe "${vehicle.name}" (${vehicle.licensePlate}) không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final res = await VehicleService.rejectVehicle(vehicle.id);
              if (!mounted) return;

              if (res['success'] == true) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Đã từ chối xe ${vehicle.name}.'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                _fetchPendingVehicles();
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(res['message'] ?? 'Lỗi khi từ chối xe'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            child: const Text('Xác nhận từ chối'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quản Trị Duyệt Xe',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Quyền Admin: Phê duyệt xe đăng tải',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: _fetchPendingVehicles,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPendingVehicles,
        child: _buildContent(currencyFormatter),
      ),
    );
  }

  Widget _buildContent(NumberFormat currencyFormatter) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang tải danh sách xe chờ duyệt...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 54, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchPendingVehicles,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_pendingVehicles.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 80, color: Colors.green.shade400),
                const SizedBox(height: 16),
                const Text(
                  'Không có xe nào đang chờ duyệt!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    'Tất cả yêu cầu đăng xe trên hệ thống đã được xử lý xong.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _fetchPendingVehicles,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Kiểm tra lại'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _pendingVehicles.length,
      itemBuilder: (context, index) {
        final vehicle = _pendingVehicles[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ảnh xe & badge trạng thái
              Stack(
                children: [
                  Container(
                    height: 160,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: (vehicle.thumbnailUrl != null && vehicle.thumbnailUrl!.isNotEmpty)
                        ? Image.network(
                            ApiEndpoints.resolveImageUrl(vehicle.thumbnailUrl!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Icon(Icons.directions_car, size: 60, color: Colors.grey),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.directions_car, size: 60, color: Colors.grey),
                          ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.hourglass_top, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Chờ Admin duyệt',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        vehicle.licensePlate,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Thông tin xe
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vehicle.name,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${vehicle.brand} • Năm SX: ${vehicle.modelYear ?? 'N/A'} • ${vehicle.seats} chỗ',
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currencyFormatter.format(vehicle.basePricePerDay),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const Text(
                              '/ ngày',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Tiện ích & cấu hình
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildChip(Icons.local_gas_station, vehicle.fuelType),
                        _buildChip(Icons.settings, vehicle.transmission == 'AUTO' ? 'Tự động' : 'Số sàn'),
                        _buildChip(
                          Icons.person,
                          vehicle.hasDriverOption ? 'Có tùy chọn tài xế' : 'Tự lái',
                          color: vehicle.hasDriverOption ? Colors.blue : Colors.grey,
                        ),
                      ],
                    ),

                    if (vehicle.address != null && vehicle.address!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              vehicle.address!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const Divider(height: 24),

                    // 2 Nút hành động phê duyệt / từ chối
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _handleReject(vehicle),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Từ chối', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _handleApprove(vehicle),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Duyệt xe', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
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
    );
  }

  Widget _buildChip(IconData icon, String label, {Color color = Colors.grey}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color == Colors.grey ? Colors.black54 : color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color == Colors.grey ? Colors.black87 : color,
            ),
          ),
        ],
      ),
    );
  }
}
