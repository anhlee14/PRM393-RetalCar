import 'package:flutter/material.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/vehicle_model.dart';
import '../../../data/services/vehicle_service.dart';
import '../../matching_explore/screens/vehicle_detail_screen.dart';
import '../../../data/services/auth_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/screens/profile_screen.dart';
import '../../vehicle_management/screens/admin_vehicle_approval_screen.dart';
import '../../vehicle_management/screens/owner_vehicle_list_screen.dart';
import '../../matching_explore/screens/explore_screen.dart';
import '../../gps_tracking/screens/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  UserModel? _currentUser;
  List<VehicleModel> _recommendedVehicles = [];
  bool _isLoadingVehicles = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    await Future.wait([
      _fetchUser(),
      _fetchRecommendedVehicles(),
    ]);
  }

  Future<void> _fetchUser() async {
    final user = await AuthService.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _currentUser = user;
    });
  }

  Future<void> _fetchRecommendedVehicles() async {
    setState(() => _isLoadingVehicles = true);
    try {
      final vehicles = await VehicleService.getAvailableVehicles();
      // Sắp xếp danh sách xe theo năm sản xuất mới nhất (modelYear giảm dần)
      vehicles.sort((a, b) {
        final yearA = a.modelYear ?? 0;
        final yearB = b.modelYear ?? 0;
        return yearB.compareTo(yearA);
      });
      if (!mounted) return;
      setState(() {
        _recommendedVehicles = vehicles.take(2).toList();
        _isLoadingVehicles = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingVehicles = false);
    }
  }

  Widget _buildHomeContent() {
    final userName = _currentUser?.fullName ?? 'Quý khách';

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Greeting Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xin chào, $userName!',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Bạn muốn tìm thuê xe hay cho thuê xe hôm nay?',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    if (_currentUser != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (ctx) => const ProfileScreen()),
                      ).then((_) => _fetchUser());
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (ctx) => const LoginScreen()),
                      ).then((_) => _fetchUser());
                    }
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary.withAlpha(40),
                    backgroundImage: (_currentUser?.avatarUrl != null && _currentUser!.avatarUrl!.isNotEmpty)
                        ? NetworkImage(_currentUser!.avatarUrl!)
                        : null,
                    child: (_currentUser?.avatarUrl == null || _currentUser!.avatarUrl!.isEmpty)
                        ? const Icon(Icons.person, color: AppColors.primary)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Banner Dành cho Admin nếu tài khoản có quyền Admin
            if (_currentUser?.role == 'ROLE_ADMIN')
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF047857), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.green.withAlpha(50), blurRadius: 6, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white24,
                      radius: 22,
                      child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 26),
                    ),
const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quản Trị Duyệt Xe Hệ Thống',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Phê duyệt hoặc từ chối các xe mới đăng ký',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF047857),
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (ctx) => const AdminVehicleApprovalScreen()),
                        );
                      },
                      child: const Text('Duyệt xe', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              )
            else
              // Banner Dành cho Chủ xe (Đăng xe cho thuê & Kiếm thu nhập)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 6, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white24,
                      radius: 22,
                      child: Icon(Icons.garage_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cho thuê xe cùng AutoRental',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Đăng tải xe, theo dõi duyệt xe & quản lý xe của bạn',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_currentUser == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng đăng nhập để quản lý xe của bạn!'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (ctx) => const LoginScreen()),
                          ).then((_) => _fetchUser());
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (ctx) => const OwnerVehicleListScreen()),
                          ).then((_) => _fetchUser());
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1E3A8A),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Quản lý xe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),

            // Search Bar (Bấm vào chuyển sang Tab Khám phá xe)
            InkWell(
              onTap: () {
                setState(() => _currentNavIndex = 1);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: AppColors.primary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tìm kiếm xe thuê (Hà Nội, TP.HCM, Đà Nẵng...)',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                    Icon(Icons.tune, color: AppColors.primary, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Promotion Banner (Smart Matching & Feature Highlights)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF0052D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withAlpha(80), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'ƯU ĐÃI THÀNG NÀY',
                      style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Thuê Xe Kèm Tài Xế Riêng\nAn Tâm Trên Mọi Nẻo Đường',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, height: 1.3),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tự động khớp xe thông minh 98% theo nhu cầu & toạ độ của bạn',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Service Categories
            const Text(
              'Dịch Vụ Cung Cấp',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildCategoryItem(
                  Icons.directions_car,
                  'Thuê tự lái',
                  Colors.blue,
                  onTap: () => setState(() => _currentNavIndex = 1),
                ),
                _buildCategoryItem(
                  Icons.person_pin,
                  'Có tài xế',
                  Colors.deepPurple,
                  onTap: () => setState(() => _currentNavIndex = 1),
                ),
                _buildCategoryItem(
                  Icons.electric_car,
                  'Xe điện',
                  Colors.green,
                  onTap: () => setState(() => _currentNavIndex = 1),
                ),
                _buildCategoryItem(
                  Icons.garage_rounded,
                  'Chủ xe',
                  Colors.orange,
                  onTap: () {
                    if (_currentUser == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng đăng nhập để vào chức năng chủ xe!'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (ctx) => const LoginScreen()),
                      ).then((_) => _fetchUser());
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (ctx) => const OwnerVehicleListScreen()),
                      ).then((_) => _fetchUser());
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Featured Recommended Cars Section (Top 2 theo năm sản xuất mới nhất)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'Xe Đề Xuất Mới Nhất',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => setState(() => _currentNavIndex = 1),
                  child: const Text('Xem tất cả', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_isLoadingVehicles)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_recommendedVehicles.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Center(
                  child: Text(
                    'Hiện chưa có xe nào sẵn sàng cho thuê.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ..._recommendedVehicles.map(
                (vehicle) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildRecommendedCarCard(vehicle),
                ),
              ),
            const SizedBox(height: 24),

            // Trust & Features Commitment Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueGrey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CAM KẾT AN TOÀN & MINH BẠCH',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                  ),
                  const SizedBox(height: 10),
                  _buildCommitmentRow(Icons.camera_alt, 'Biên bản thẩm định 6 góc ảnh Trước & Sau bàn giao.'),
                  const SizedBox(height: 8),
                  _buildCommitmentRow(Icons.shield, 'Bảo vệ riêng tư GPS: Chủ xe giới hạn 20 lượt kiểm tra/ngày.'),
                  const SizedBox(height: 8),
                  _buildCommitmentRow(Icons.alarm, 'Hệ thống cảnh báo an toàn GPS quá 60 phút tự động.'),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommitmentRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.black87)),
        ),
      ],
    );
  }

  Widget _buildRecommendedCarCard(VehicleModel vehicle) {
    final year = vehicle.modelYear != null ? 'Đời ${vehicle.modelYear}' : 'Mới nhất';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => VehicleDetailScreen(vehicle: vehicle),
          ),
        ).then((_) => _fetchRecommendedVehicles());
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh xe + Badge Đề xuất theo năm sản xuất
            Stack(
              children: [
                (vehicle.thumbnailUrl != null && vehicle.thumbnailUrl!.isNotEmpty)
                    ? Image.network(
                        ApiEndpoints.resolveImageUrl(vehicle.thumbnailUrl!),
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          height: 160,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(Icons.directions_car, size: 54, color: Colors.grey),
                          ),
                        ),
                      )
                    : Container(
                        height: 160,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.directions_car, size: 54, color: Colors.grey),
                        ),
                      ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'ĐỀ XUẤT • $year',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(180),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${CurrencyFormatter.format(vehicle.basePricePerDay)}/ngày',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
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
                          vehicle.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${vehicle.brand} • ${vehicle.seats} chỗ • ${vehicle.transmission == 'AUTO' ? 'Tự động' : 'Số sàn'} • ${vehicle.fuelType}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),

                  // Feature 1: Huy hiệu kèm tài xế
                  if (vehicle.hasDriverOption)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.deepPurple.shade100),
                      ),
                      child: Text(
                        'Hỗ trợ kèm tài xế (+${CurrencyFormatter.format(vehicle.driverFeePerDay)}/ngày)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.deepPurple.shade800,
                          fontWeight: FontWeight.w600,
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
                        'Thuê xe tự lái',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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

  Widget _buildMyBookingsStub() {
    return Scaffold(
      appBar: AppBar(title: const Text('Xe Đã Thuê Của Tôi')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long_rounded, size: 64, color: Colors.deepPurple),
              ),
              const SizedBox(height: 20),
              const Text(
                'Lịch Sử Chuyến Đi & Đơn Thuê',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Quản lý đơn thuê xe, duyệt đơn & thanh toán tiền cọc',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => setState(() => _currentNavIndex = 0),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Quay lại Trang chủ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedBody() {
    switch (_currentNavIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const ExploreScreen(); // Tab 2: Khám phá xe & Matching %
      case 2:
        return _buildMyBookingsStub();  // Tab 3: Xe đã thuê / Đơn thuê
      case 3:
      default:
        return const ProfileScreen(); // Tab 4: Tài khoản cá nhân
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentNavIndex == 0
          ? AppBar(
              title: const Text('AutoRental'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  tooltip: 'Thông báo',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    );
                  },
                ),
              ],
            )
          : null,
      body: _buildSelectedBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentNavIndex,
        onDestinationSelected: (idx) {
          setState(() => _currentNavIndex = idx);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car),
            label: 'Danh sách xe',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Xe đã thuê',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}
