import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/inspection_model.dart';
import '../../../data/services/inspection_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckInReviewScreen extends StatefulWidget {
  final int bookingId;

  const CheckInReviewScreen({super.key, required this.bookingId});

  @override
  State<CheckInReviewScreen> createState() => _CheckInReviewScreenState();
}

class _CheckInReviewScreenState extends State<CheckInReviewScreen> {
  InspectionComparisonModel? _comparison;
  bool _isLoading = true;
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _fetchCheckIn();
  }

  Future<void> _fetchCheckIn() async {
    setState(() => _isLoading = true);
    final comp = await InspectionService.getComparison(widget.bookingId);
    if (!mounted) return;
    setState(() {
      _comparison = comp;
      _isLoading = false;
    });
  }

  void _loadMockCheckIn() {
    setState(() {
      _comparison = InspectionComparisonModel(
        bookingId: widget.bookingId == 0 ? 101 : widget.bookingId,
        vehicleName: 'VinFast VF8 Plus 2024',
        licensePlate: '30K-888.99',
        checkIn: InspectionModel(
          id: 501,
          bookingId: widget.bookingId == 0 ? 101 : widget.bookingId,
          stage: 'CHECK_IN',
          frontImg: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/2022_Vinfast_VF8_front_view.jpg/1280px-2022_Vinfast_VF8_front_view.jpg',
          rearImg: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1b/VinFast_VF_8_DSC_8470.jpg/1280px-VinFast_VF_8_DSC_8470.jpg',
          leftImg: 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341',
          rightImg: 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341',
          odoImg: 'https://images.unsplash.com/photo-1542282088-72c9c27ed0cd',
          fuelImg: 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d',
          odoKm: 15200.0,
          fuelLevelPercent: 100.0,
          notes: 'Chủ xe bàn giao xe sạch sẽ, đầy pin, nguyên bản không trầy xước.',
          isConfirmedByRenter: false,
          isConfirmedByOwner: true,
        ),
        checkOut: null,
        odoDifferenceKm: 0.0,
        fuelDifferencePercent: 0.0,
        isFullyConfirmed: false,
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã nạp biên bản giao xe mẫu của chủ xe để thử nghiệm!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  
  Future<void> _recordCheckInConfirmed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('renter_confirmed_checkin_bookings') ?? [];
      final idStr = widget.bookingId.toString();
      if (!list.contains(idStr)) {
        list.add(idStr);
        await prefs.setStringList('renter_confirmed_checkin_bookings', list);
      }
    } catch (_) {}
  }

  Future<void> _handleConfirmReceipt() async {
    final checkInId = _comparison?.checkIn?.id;
    if (checkInId == null || checkInId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy mã biên bản để xác nhận.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified_rounded, color: AppColors.success),
            SizedBox(width: 8),
            Text('Xác Nhận Nhận Xe', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Bạn xác nhận đã kiểm tra thực tế hiện trạng xe, số km trên đồng hồ ODO và mức xăng/pin đúng như biên bản bàn giao của chủ xe?',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Xem lại'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận nhận xe'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isConfirming = true);

    try {
      final ok = await InspectionService.confirmInspection(checkInId);
      if (!mounted) return;

      if (ok) {
        await _recordCheckInConfirmed();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bạn đã xác nhận biên bản nhận xe thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
        _fetchCheckIn();
        Navigator.pop(context, true);
      } else {
        // Fallback thử nghiệm cục bộ
        setState(() {
          if (_comparison != null && _comparison!.checkIn != null) {
            final ci = _comparison!.checkIn!;
            _comparison = InspectionComparisonModel(
              bookingId: _comparison!.bookingId,
              vehicleName: _comparison!.vehicleName,
              licensePlate: _comparison!.licensePlate,
              checkIn: InspectionModel(
                id: ci.id,
                bookingId: ci.bookingId,
                stage: ci.stage,
                frontImg: ci.frontImg,
                rearImg: ci.rearImg,
                leftImg: ci.leftImg,
                rightImg: ci.rightImg,
                odoImg: ci.odoImg,
                fuelImg: ci.fuelImg,
                odoKm: ci.odoKm,
                fuelLevelPercent: ci.fuelLevelPercent,
                notes: ci.notes,
                isConfirmedByRenter: true,
                isConfirmedByOwner: ci.isConfirmedByOwner,
              ),
              checkOut: _comparison!.checkOut,
              odoDifferenceKm: _comparison!.odoDifferenceKm,
              fuelDifferencePercent: _comparison!.fuelDifferencePercent,
              isFullyConfirmed: _comparison!.isFullyConfirmed,
            );
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xác nhận nhận xe thành công (Chế độ Thử nghiệm)!'),
            backgroundColor: AppColors.success,
          ),
        );
        await _recordCheckInConfirmed();
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  void _showZoomImage(String title, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: const EdgeInsets.all(24),
                    color: Colors.white,
                    child: const Text('Không thể tải hình ảnh.'),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Biên Bản Nhận Xe (Chủ Xe Giao)'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Nạp dữ liệu mẫu',
            onPressed: _loadMockCheckIn,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: _fetchCheckIn,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _comparison?.checkIn == null
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchCheckIn,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Thẻ Tóm tắt Cuốc xe & Trạng thái
                        _buildTripHeaderCard(_comparison!),
                        const SizedBox(height: 16),

                        // 2. Chỉ số ODO & Xăng bàn giao
                        _buildMetricsCard(_comparison!.checkIn!),
                        const SizedBox(height: 16),

                        // 3. Lưới 6 góc ảnh chủ xe đã chụp bàn giao
                        _buildPhotoGridSection(_comparison!.checkIn!),
                        const SizedBox(height: 16),

                        // 4. Ghi chú bàn giao
                        _buildNotesCard(_comparison!.checkIn!),
                        const SizedBox(height: 20),

                        // 5. Nút Ký Xác nhận Nhận xe
                        _buildActionButton(_comparison!.checkIn!),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Icon(Icons.hourglass_top_rounded, size: 64, color: Colors.orange.shade800),
            ),
            const SizedBox(height: 18),
            const Text(
              'Chờ Chủ Xe Check-in Giao Xe',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Chủ xe chưa lập biên bản bàn giao xe. Khi bạn gặp chủ xe nhận chìa khóa, chủ xe sẽ chụp 6 góc ảnh hiện trạng và gửi lên đây để bạn kiểm tra và xác nhận.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _fetchCheckIn,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Kiểm tra lại'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _loadMockCheckIn,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Xem mẫu giao xe'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripHeaderCard(InspectionComparisonModel comp) {
    final checkIn = comp.checkIn;
    final isConfirmed = checkIn?.isConfirmedByRenter ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.car_rental_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#BK-${comp.bookingId}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isConfirmed
                            ? AppColors.success.withValues(alpha: 0.15)
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isConfirmed ? 'ĐÃ XÁC NHẬN NHẬN XE' : 'CHỜ BẠN XÁC NHẬN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isConfirmed ? AppColors.success : Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comp.vehicleName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  'Biển số: ${comp.licensePlate}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsCard(InspectionModel checkIn) {
    final odo = checkIn.odoKm ?? 0.0;
    final fuel = checkIn.fuelLevelPercent ?? 100.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.speed_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Chỉ Số Bàn Giao Từ Chủ Xe',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đồng hồ ODO ban đầu',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${odo.toInt()} km',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mức Nhiên liệu / Pin',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${fuel.toInt()} %',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.success),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGridSection(InspectionModel checkIn) {
    final photos = [
      _PhotoItem('1. Đầu xe (Front)', checkIn.frontImg),
      _PhotoItem('2. Đuôi xe (Rear)', checkIn.rearImg),
      _PhotoItem('3. Sườn trái xe (Left)', checkIn.leftImg),
      _PhotoItem('4. Sườn phải xe (Right)', checkIn.rightImg),
      _PhotoItem('5. Đồng hồ ODO (km)', checkIn.odoImg),
      _PhotoItem('6. Mức xăng / Pin (%)', checkIn.fuelImg),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Row(
                children: [
                  Icon(Icons.photo_library_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Ảnh Hiện Trạng Chủ Xe Chụp',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                'Chạm để xem ảnh lớn',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: photos.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.25,
            ),
            itemBuilder: (ctx, idx) {
              final item = photos[idx];
              final hasUrl = item.url != null && item.url!.isNotEmpty;

              return InkWell(
                onTap: hasUrl ? () => _showZoomImage(item.title, item.url!) : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (hasUrl)
                          Image.network(
                            item.url!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Icon(Icons.broken_image_rounded, color: Colors.grey),
                            ),
                          )
                        else
                          const Center(
                            child: Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                          ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            color: Colors.black54,
                            child: Text(
                              item.title,
                              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(InspectionModel checkIn) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.notes_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Ghi Chú Bàn Giao Của Chủ Xe',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            (checkIn.notes != null && checkIn.notes!.trim().isNotEmpty)
                ? checkIn.notes!
                : 'Không có ghi chú thêm từ chủ xe.',
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(InspectionModel checkIn) {
    final isConfirmed = checkIn.isConfirmedByRenter;

    if (isConfirmed) {
      return Container(
        padding: const EdgeInsets.all(14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.success),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.verified_rounded, color: AppColors.success),
            SizedBox(width: 8),
            Text(
              'BẠN ĐÃ XÁC NHẬN BIÊN BẢN NHẬN XE',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.success),
            ),
          ],
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: _isConfirming ? null : _handleConfirmReceipt,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 2,
      ),
      icon: _isConfirming
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.check_circle_rounded),
      label: const Text(
        'TÔI ĐÃ KIỂM TRA & XÁC NHẬN NHẬN XE',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }
}

class _PhotoItem {
  final String title;
  final String? url;

  _PhotoItem(this.title, this.url);
}
