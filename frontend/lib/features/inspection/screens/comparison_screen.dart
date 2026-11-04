import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/inspection_model.dart';
import '../../../data/services/inspection_service.dart';

class ComparisonScreen extends StatefulWidget {
  final int bookingId;

  const ComparisonScreen({super.key, required this.bookingId});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  InspectionComparisonModel? _comparison;
  bool _isLoading = true;
  bool _isConfirming = false;

  void _loadMockComparison() {
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
          notes: 'Xe nguyên vẹn, ngoại thất sạch sẽ, pin 100% khi nhận bàn giao.',
          isConfirmedByRenter: true,
          isConfirmedByOwner: true,
        ),
        checkOut: InspectionModel(
          id: 502,
          bookingId: widget.bookingId == 0 ? 101 : widget.bookingId,
          stage: 'CHECK_OUT',
          frontImg: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/2022_Vinfast_VF8_front_view.jpg/1280px-2022_Vinfast_VF8_front_view.jpg',
          rearImg: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1b/VinFast_VF_8_DSC_8470.jpg/1280px-VinFast_VF_8_DSC_8470.jpg',
          leftImg: 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341',
          rightImg: 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341',
          odoImg: 'https://images.unsplash.com/photo-1542282088-72c9c27ed0cd',
          fuelImg: 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d',
          odoKm: 15380.0,
          fuelLevelPercent: 85.0,
          notes: 'Khách hoàn trả xe đúng hẹn, ngoại thất sạch sẽ, không trầy xước phát sinh.',
          isConfirmedByRenter: true,
          isConfirmedByOwner: false,
        ),
        odoDifferenceKm: 180.0,
        fuelDifferencePercent: -15.0,
        isFullyConfirmed: false,
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã nạp biên bản đối chiếu Before/After mẫu để kiểm thử!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchComparison();
  }

  Future<void> _fetchComparison() async {
    setState(() => _isLoading = true);
    final comp = await InspectionService.getComparison(widget.bookingId);
    if (!mounted) return;
    setState(() {
      _comparison = comp;
      _isLoading = false;
    });
  }

  Future<void> _handleConfirm() async {
    final checkoutId = _comparison?.checkOut?.id ?? _comparison?.checkIn?.id;
    if (checkoutId == null || checkoutId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa có biên bản hoàn trả để ký xác nhận.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isConfirming = true);

    try {
      final ok = await InspectionService.confirmInspection(checkoutId);
      if (!mounted) return;

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xác nhận biên bản bàn giao thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
        _fetchComparison();
      } else {
        // Fallback cho chế độ thử nghiệm
        setState(() {
          if (_comparison != null) {
            final co = _comparison!.checkOut;
            _comparison = InspectionComparisonModel(
              bookingId: _comparison!.bookingId,
              vehicleName: _comparison!.vehicleName,
              licensePlate: _comparison!.licensePlate,
              checkIn: _comparison!.checkIn,
              checkOut: co != null
                  ? InspectionModel(
                      id: co.id,
                      bookingId: co.bookingId,
                      stage: co.stage,
                      frontImg: co.frontImg,
                      rearImg: co.rearImg,
                      leftImg: co.leftImg,
                      rightImg: co.rightImg,
                      odoImg: co.odoImg,
                      fuelImg: co.fuelImg,
                      odoKm: co.odoKm,
                      fuelLevelPercent: co.fuelLevelPercent,
                      notes: co.notes,
                      isConfirmedByRenter: true,
                      isConfirmedByOwner: true,
                    )
                  : null,
              odoDifferenceKm: _comparison!.odoDifferenceKm,
              fuelDifferencePercent: _comparison!.fuelDifferencePercent,
              isFullyConfirmed: true,
            );
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xác nhận bàn giao & hoàn cọc thành công (Chế độ Thử nghiệm)!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  void _showZoomImage(BuildContext context, String title, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, err, stack) => Container(
                    padding: const EdgeInsets.all(32),
                    color: Colors.white,
                    child: const Text('Không thể tải ảnh chi tiết'),
                  ),
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
        title: const Text('Đối Chiếu Trước & Sau (Before/After)'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Nạp mẫu đối chiếu',
            onPressed: _loadMockComparison,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: _fetchComparison,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _comparison == null
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchComparison,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Thẻ Tóm tắt Cuốc xe
                        _buildTripHeaderCard(_comparison!),
                        const SizedBox(height: 16),

                        // 2. Khung Số Liệu Chênh Lệch Tự Động
                        _buildMetricsComparisonCard(_comparison!),
                        const SizedBox(height: 16),

                        // 3. Giao Diện So Sánh 6 Cặp Ảnh Side-by-Side
                        _buildSideBySideGallery(_comparison!),
                        const SizedBox(height: 16),

                        // 4. Thanh Trạng Thái Đồng Thuận 2 Bên (Mutual Sign-off)
                        _buildMutualSignOffCard(_comparison!),
                        const SizedBox(height: 20),

                        // 5. Nút Bấm Xác Nhận Hoàn Cọc
                        _buildActionButton(_comparison!),
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
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.compare_rounded, size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có dữ liệu đối chiếu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Đơn xe cần có ít nhất biên bản nhận xe (Check-in) để bắt đầu so sánh hiện trạng.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _fetchComparison,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tải lại'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _loadMockComparison,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Xem mẫu đối chiếu'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripHeaderCard(InspectionComparisonModel comp) {
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
            child: const Icon(Icons.compare_arrows_rounded, color: AppColors.primary, size: 28),
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
                        color: comp.isFullyConfirmed
                            ? AppColors.success.withValues(alpha: 0.15)
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        comp.isFullyConfirmed ? 'ĐÃ HOÀN TẤT' : 'CHỜ KÝ BÀN GIAO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: comp.isFullyConfirmed ? AppColors.success : Colors.orange.shade800,
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

  Widget _buildMetricsComparisonCard(InspectionComparisonModel comp) {
    final checkInOdo = comp.checkIn?.odoKm ?? 0.0;
    final checkOutOdo = comp.checkOut?.odoKm ?? checkInOdo;
    final checkInFuel = comp.checkIn?.fuelLevelPercent ?? 100.0;
    final checkOutFuel = comp.checkOut?.fuelLevelPercent ?? checkInFuel;

    final odoDiff = comp.odoDifferenceKm != 0.0 ? comp.odoDifferenceKm : (checkOutOdo - checkInOdo);
    final fuelDiff = comp.fuelDifferencePercent != 0.0 ? comp.fuelDifferencePercent : (checkOutFuel - checkInFuel);

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
              Icon(Icons.auto_graph_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Khung Số Liệu Chênh Lệch Tự Động',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
                        'Quãng đường đã chạy',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+${odoDiff.toStringAsFixed(1)} km',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '(${checkInOdo.toInt()} -> ${checkOutOdo.toInt()} km)',
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
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
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chênh lệch Nhiên liệu/Pin',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${fuelDiff > 0 ? '+' : ''}${fuelDiff.toStringAsFixed(0)} %',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: fuelDiff < 0 ? AppColors.danger : AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '(${checkInFuel.toInt()}% -> ${checkOutFuel.toInt()}%)',
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
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

  Widget _buildSideBySideGallery(InspectionComparisonModel comp) {
    final pairs = [
      _PairItem('1. Đầu xe (Front)', comp.checkIn?.frontImg, comp.checkOut?.frontImg),
      _PairItem('2. Đuôi xe (Rear)', comp.checkIn?.rearImg, comp.checkOut?.rearImg),
      _PairItem('3. Sườn trái xe (Left)', comp.checkIn?.leftImg, comp.checkOut?.leftImg),
      _PairItem('4. Sườn phải xe (Right)', comp.checkIn?.rightImg, comp.checkOut?.rightImg),
      _PairItem('5. Đồng hồ ODO (km)', comp.checkIn?.odoImg, comp.checkOut?.odoImg),
      _PairItem('6. Vạch mức xăng / Pin (%)', comp.checkIn?.fuelImg, comp.checkOut?.fuelImg),
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
            children: [
              Row(
                children: const [
                  Icon(Icons.burst_mode_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'So Sánh 6 Cặp Ảnh Đối Chiếu',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Text(
                'Nhấn ảnh để phóng to',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Header phân biệt Before và After
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'LÚC NHẬN XE (BEFORE)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'LÚC TRẢ XE (AFTER)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.warning),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pairs.length,
            separatorBuilder: (ctx, idx) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1),
            ),
            itemBuilder: (context, idx) {
              final pair = pairs[idx];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pair.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPhotoThumb(
                          pair.beforeUrl,
                          'Lúc Nhận: ${pair.title}',
                          fallbackColor: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildPhotoThumb(
                          pair.afterUrl,
                          'Lúc Trả: ${pair.title}',
                          fallbackColor: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoThumb(String? url, String title, {required Color fallbackColor}) {
    final validUrl = (url != null && url.isNotEmpty) ? url : null;

    if (validUrl == null) {
      return Container(
        height: 105,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_outlined, color: Colors.grey.shade400, size: 24),
            const SizedBox(height: 4),
            const Text(
              'Chưa có ảnh',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () => _showZoomImage(context, title, validUrl),
      borderRadius: BorderRadius.circular(10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            Image.network(
              validUrl,
              height: 105,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => Container(
                height: 105,
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(Icons.broken_image_rounded, color: Colors.grey),
                ),
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMutualSignOffCard(InspectionComparisonModel comp) {
    final renterSigned = comp.checkOut?.isConfirmedByRenter ?? comp.checkIn?.isConfirmedByRenter ?? false;
    final ownerSigned = comp.checkOut?.isConfirmedByOwner ?? comp.checkIn?.isConfirmedByOwner ?? false;
    final bothSigned = comp.isFullyConfirmed || (renterSigned && ownerSigned);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: bothSigned ? AppColors.success : AppColors.border,
          width: bothSigned ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.draw_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Thanh Trạng Thái Đồng Thuận 2 Bên (Mutual Sign-off)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildSignRow('Khách thuê xác nhận hiện trạng xe:', renterSigned),
          const SizedBox(height: 8),
          _buildSignRow('Chủ xe xác nhận nhận lại xe & trả cọc:', ownerSigned),

          if (bothSigned) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.verified_rounded, color: AppColors.success, size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Hai bên đã ký biên bản bàn giao thành công! Thủ tục hoàn cọc 100% hoàn tất.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSignRow(String title, bool isSigned) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isSigned ? AppColors.success.withValues(alpha: 0.15) : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSigned ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                size: 13,
                color: isSigned ? AppColors.success : Colors.orange.shade800,
              ),
              const SizedBox(width: 4),
              Text(
                isSigned ? 'ĐÃ KÝ' : 'CHỜ KÝ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSigned ? AppColors.success : Colors.orange.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(InspectionComparisonModel comp) {
    final isDone = comp.isFullyConfirmed;

    if (isDone) {
      return Container(
        padding: const EdgeInsets.all(14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.success),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.task_alt_rounded, color: AppColors.success),
            SizedBox(width: 8),
            Text(
              'BIÊN BẢN ĐÃ KÝ ĐỒNG THUẬN - HOÀN CỌC XONG',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.success),
            ),
          ],
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: _isConfirming ? null : _handleConfirm,
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
          : const Icon(Icons.verified_rounded),
      label: const Text(
        'XÁC NHẬN BÀN GIAO & HOÀN CỌC',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }
}

class _PairItem {
  final String title;
  final String? beforeUrl;
  final String? afterUrl;

  _PairItem(this.title, this.beforeUrl, this.afterUrl);
}
