import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/vehicle_image_helper.dart';
import '../../../data/models/vehicle_model.dart';
import '../../../data/services/vehicle_service.dart';
import '../widgets/matching_filter_sheet.dart';
import 'vehicle_detail_screen.dart';
import '../../gps_tracking/screens/notifications_screen.dart';
import '../../gps_tracking/screens/renter_route_map_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Danh sách xe đã nạp
  List<VehicleMatchModel> _allMatches = [];
  List<VehicleMatchModel> _filteredMatches = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Tiêu chí Matching Filter
  double _budget = 2000000;
  bool _needDriver = false;
  String _selectedCategory = 'ALL';
  double _budgetWeight = 0.35;
  double _distanceWeight = 0.35;
  double _driverWeight = 0.30;

  // Toạ độ mặc định (Khu CNC Hòa Lạc / ĐH FPT)
  final double _userLat = 21.0131;
  final double _userLng = 105.5255;

  final List<Map<String, dynamic>> _quickCategories = [
    {'label': 'Tất cả', 'value': 'ALL', 'icon': Icons.apps_rounded},
    {'label': 'Có tài xế riêng', 'value': 'WITH_DRIVER', 'icon': Icons.person_pin_circle_rounded},
    {'label': 'SUV gầm cao', 'value': 'SUV', 'icon': Icons.directions_car_filled_rounded},
    {'label': 'Sedan sang trọng', 'value': 'SEDAN', 'icon': Icons.directions_car_rounded},
    {'label': 'MPV 7 chỗ', 'value': 'MPV', 'icon': Icons.airport_shuttle_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _fetchMatchingVehicles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMatchingVehicles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await VehicleService.searchMatchingVehicles(
        budget: _budget,
        needDriver: _needDriver,
        userLat: _userLat,
        userLng: _userLng,
        vehicleType: (_selectedCategory != 'ALL' && _selectedCategory != 'WITH_DRIVER')
            ? _selectedCategory
            : null,
        budgetWeight: _budgetWeight,
        distanceWeight: _distanceWeight,
        driverWeight: _driverWeight,
      );

      setState(() {
        _allMatches = results;
        _applyLocalFilters();
        _isLoading = false;
      });
    } catch (e) {
      // Fallback: Lấy danh sách xe thông thường nếu API match có lỗi
      try {
        final fallbackList = await VehicleService.getAvailableVehicles();
        setState(() {
          _allMatches = fallbackList
              .map((v) => VehicleMatchModel(
                    vehicle: v,
                    matchScore: 85.0,
                    distanceKm: 2.5,
                    matchLabel: 'Phù hợp',
                  ))
              .toList();
          _applyLocalFilters();
          _isLoading = false;
        });
      } catch (err) {
        setState(() {
          _errorMessage = 'Không thể tải danh sách xe. Vui lòng thử lại!';
          _isLoading = false;
        });
      }
    }
  }

  void _applyLocalFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredMatches = _allMatches.where((item) {
        final v = item.vehicle;
        // Lọc theo search keyword
        final matchSearch = query.isEmpty ||
            v.name.toLowerCase().contains(query) ||
            v.brand.toLowerCase().contains(query) ||
            v.licensePlate.toLowerCase().contains(query);

        // Lọc theo Quick Category
        bool matchCat = true;
        if (_selectedCategory == 'WITH_DRIVER') {
          matchCat = v.hasDriverOption;
        } else if (_selectedCategory != 'ALL') {
          matchCat = v.vehicleType.toUpperCase() == _selectedCategory.toUpperCase();
        }

        return matchSearch && matchCat;
      }).toList();
    });
  }

  void _openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: MatchingFilterSheet(
            budget: _budget,
            needDriver: _needDriver,
            vehicleType: _selectedCategory,
            budgetWeight: _budgetWeight,
            distanceWeight: _distanceWeight,
            driverWeight: _driverWeight,
            onApply: ({
              required double budget,
              required bool needDriver,
              required String? vehicleType,
              required double budgetWeight,
              required double distanceWeight,
              required double driverWeight,
            }) {
              setState(() {
                _budget = budget;
                _needDriver = needDriver;
                _selectedCategory = vehicleType ?? 'ALL';
                _budgetWeight = budgetWeight;
                _distanceWeight = distanceWeight;
                _driverWeight = driverWeight;
              });
              _fetchMatchingVehicles();
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.car_rental_rounded, size: 22, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AutoRental',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'Thuê Xe & Matching Thông Minh',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Định vị GPS xe',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RenterRouteMapScreen(bookingId: 1)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Thông báo',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchMatchingVehicles,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // 1. Search Bar & Filter Button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => _applyLocalFilters(),
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm xe (VinFast, Vios, MPV...)',
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      _applyLocalFilters();
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.tune_rounded, color: Colors.white),
                        tooltip: 'Bộ lọc Matching Sliders',
                        onPressed: _openFilterBottomSheet,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Banner Thuật Toán Thông Minh (Nghiệp vụ 4)
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: _openFilterBottomSheet,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade600, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 26),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thuật Toán Matching % Thông Minh',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Hệ thống tự động chấm điểm theo vị trí GPS, ngân sách và nhu cầu tài xế.',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Thanh Phân Loại Nhanh (Category Chips)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _quickCategories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = _quickCategories[index];
                    final isSelected = _selectedCategory == cat['value'];
                    return ChoiceChip(
                      avatar: Icon(
                        cat['icon'] as IconData,
                        size: 16,
                        color: isSelected ? Colors.white : AppColors.primary,
                      ),
                      label: Text(cat['label'] as String),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12,
                      ),
                      elevation: isSelected ? 2 : 0,
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : Colors.grey.shade300,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = cat['value'] as String;
                          _applyLocalFilters();
                        });
                      },
                    );
                  },
                ),
              ),
            ),

            // 4. Tiêu đề danh sách xe & số lượng tìm thấy
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Xe Phù Hợp Nhất (${_filteredMatches.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (_needDriver || _selectedCategory != 'ALL')
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = 'ALL';
                            _needDriver = false;
                            _searchController.clear();
                            _fetchMatchingVehicles();
                          });
                        },
                        child: const Row(
                          children: [
                            Icon(Icons.restart_alt_rounded, size: 14, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text(
                              'Đặt lại',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 5. Danh Sách Thẻ Xe Hoặc Trạng Thái
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 16),
                      Text(
                        'Đang tính toán điểm Matching %...',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else if (_errorMessage != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade300),
                      const SizedBox(height: 12),
                      Text(_errorMessage!, style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                        onPressed: _fetchMatchingVehicles,
                      ),
                    ],
                  ),
                ),
              )
            else if (_filteredMatches.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'Không tìm thấy xe phù hợp',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Hãy thử nới lỏng ngân sách hoặc chọn Tất cả loại xe',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.tune_rounded),
                        label: const Text('Mở bộ lọc Matching'),
                        onPressed: _openFilterBottomSheet,
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = _filteredMatches[index];
                      return _buildVehicleCard(item);
                    },
                    childCount: _filteredMatches.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Widget Thẻ Xe với Badge Matching Score
  Widget _buildVehicleCard(VehicleMatchModel match) {
    final v = match.vehicle;
    final score = match.matchScore;

    // Phân loại màu cho điểm Matching
    Color badgeColor;
    String badgeLabel;
    if (score >= 80) {
      badgeColor = const Color(0xFF2E7D32); // Xanh lá đậm (Rất phù hợp)
      badgeLabel = '${score.toStringAsFixed(0)}% MATCH';
    } else if (score >= 50) {
      badgeColor = const Color(0xFFE65100); // Cam hổ phách (Phù hợp)
      badgeLabel = '${score.toStringAsFixed(0)}% MATCH';
    } else {
      badgeColor = Colors.grey.shade700;
      badgeLabel = '${score.toStringAsFixed(0)}% MATCH';
    }

    final imageUrl = VehicleImageHelper.getThumbnail(v);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VehicleDetailScreen(
                  vehicle: v,
                  matchScore: score,
                  matchLabel: match.matchLabel,
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ảnh xe + Huy hiệu Matching % góc phải
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.directions_car, size: 64, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),

                  // Huy hiệu Tỉ lệ khớp % (Feature 4)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            badgeLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Badge Loại xe ở góc trái
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        v.vehicleType,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Thông tin chi tiết của xe
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên xe & Đánh giá
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${v.brand} • ${v.licensePlate}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                            const SizedBox(width: 2),
                            Text(
                              v.averageRating.toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Thông số kỹ thuật nhanh (Specs Chips)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildSpecChip(Icons.airline_seat_recline_normal, '${v.seats} chỗ'),
                        _buildSpecChip(Icons.settings_outlined, v.transmission),
                        _buildSpecChip(Icons.local_gas_station_outlined, v.fuelType),
                        if (match.distanceKm != null)
                          _buildSpecChip(Icons.near_me_rounded, '${match.distanceKm!.toStringAsFixed(1)} km', isDistance: true),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Huy hiệu có tài xế riêng (Nghiệp vụ 1)
                    if (v.hasDriverOption)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purple.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_pin_circle_rounded, size: 14, color: Colors.purple.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'Có tài xế riêng (+${CurrencyFormatter.format(v.driverFeePerDay)}/ngày)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const Divider(height: 14),

                    // Giá thuê & Nút Đặt xe
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Giá tự lái chỉ từ:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            Text(
                              CurrencyFormatter.format(v.basePricePerDay),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Text(
                                'Xem Chi Tiết',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.chevron_right, color: Colors.white, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecChip(IconData icon, String text, {bool isDistance = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDistance ? Colors.blue.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDistance ? Colors.blue.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: isDistance ? AppColors.primary : Colors.grey.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isDistance ? FontWeight.bold : FontWeight.w500,
              color: isDistance ? AppColors.primaryDark : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
