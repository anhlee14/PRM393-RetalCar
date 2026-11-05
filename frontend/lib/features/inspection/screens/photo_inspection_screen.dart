import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/inspection_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhotoInspectionScreen extends StatefulWidget {
  final int bookingId;
  final String stage; // 'CHECK_IN' hoặc 'CHECK_OUT'
  final bool? isOwner;
  final String? title;
  final String? submitButtonText;

  const PhotoInspectionScreen({
    super.key,
    required this.bookingId,
    this.stage = 'CHECK_IN',
    this.isOwner,
    this.title,
    this.submitButtonText,
  });

  @override
  State<PhotoInspectionScreen> createState() => _PhotoInspectionScreenState();
}

class _PhotoSlot {
  final String key;
  final String title;
  final IconData icon;
  XFile? file;
  Uint8List? bytes;
  String? uploadedUrl;

  _PhotoSlot({
    required this.key,
    required this.title,
    required this.icon,
  });
}

class _PhotoInspectionScreenState extends State<PhotoInspectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late final List<_PhotoSlot> _slots;
  late final TextEditingController _odoController;
  late final TextEditingController _fuelController;
  late final TextEditingController _notesController;

  bool _isSubmitting = false;

  bool get _isCheckIn => widget.stage.toUpperCase() == 'CHECK_IN';

  @override
  void initState() {
    super.initState();
    _slots = [
      _PhotoSlot(key: 'front', title: '1. Đầu xe (Front)', icon: Icons.directions_car_rounded),
      _PhotoSlot(key: 'rear', title: '2. Đuôi xe (Rear)', icon: Icons.car_repair_rounded),
      _PhotoSlot(key: 'left', title: '3. Sườn trái (Left Side)', icon: Icons.arrow_back_rounded),
      _PhotoSlot(key: 'right', title: '4. Sườn phải (Right Side)', icon: Icons.arrow_forward_rounded),
      _PhotoSlot(key: 'odo', title: '5. Đồng hồ ODO (km)', icon: Icons.speed_rounded),
      _PhotoSlot(key: 'fuel', title: '6. Mức xăng / Pin (%)', icon: Icons.local_gas_station_rounded),
    ];

    _odoController = TextEditingController(text: _isCheckIn ? '15200' : '15380');
    _fuelController = TextEditingController(text: _isCheckIn ? '100' : '90');
    _notesController = TextEditingController(
      text: _isCheckIn
          ? 'Xe ngoại thất sạch sẽ, vết trầy nhẹ cản sau bên phụ có từ trước.'
          : 'Trả xe đúng hẹn, xe nguyên vẹn, nội thất sạch sẽ.',
    );
  }

  @override
  void dispose() {
    _odoController.dispose();
    _fuelController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(int index, ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _slots[index].file = picked;
          _slots[index].bytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể chụp/chọn ảnh: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showImageSourceSheet(int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chụp ảnh ${_slots[index].title}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                ),
                title: const Text('Mở Máy ảnh (Camera)'),
                subtitle: const Text('Chụp trực tiếp hiện trạng thực tế'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(index, ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.accent),
                ),
                title: const Text('Chọn từ Thư viện ảnh'),
                subtitle: const Text('Tải ảnh có sẵn trên máy'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(index, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearImage(int index) {
    setState(() {
      _slots[index].file = null;
      _slots[index].bytes = null;
      _slots[index].uploadedUrl = null;
    });
  }

  // Fallback demo URL nếu người dùng không chụp ảnh thực tế
  String _getDefaultSamplePhoto(String key, bool isCheckIn) {
    switch (key) {
      case 'front':
        return isCheckIn
            ? 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/2022_Vinfast_VF8_front_view.jpg/1280px-2022_Vinfast_VF8_front_view.jpg'
            : 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/2022_Vinfast_VF8_front_view.jpg/1280px-2022_Vinfast_VF8_front_view.jpg';
      case 'rear':
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1b/VinFast_VF_8_DSC_8470.jpg/1280px-VinFast_VF_8_DSC_8470.jpg';
      case 'left':
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1b/VinFast_VF_8_DSC_8470.jpg/1280px-VinFast_VF_8_DSC_8470.jpg';
      case 'right':
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1b/VinFast_VF_8_DSC_8470.jpg/1280px-VinFast_VF_8_DSC_8470.jpg';
      case 'odo':
        return 'https://images.unsplash.com/photo-1542282088-72c9c27ed0cd';
      case 'fuel':
        return 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d';
      default:
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/2022_Vinfast_VF8_front_view.jpg/1280px-2022_Vinfast_VF8_front_view.jpg';
    }
  }

  
  Future<void> _recordInspectionSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _isCheckIn ? 'checked_in_bookings' : 'checked_out_bookings';
      final list = prefs.getStringList(key) ?? [];
      final idStr = widget.bookingId.toString();
      if (!list.contains(idStr)) {
        list.add(idStr);
        await prefs.setStringList(key, list);
      }
    } catch (_) {}
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final Map<String, String> photoUrls = {};

      for (var slot in _slots) {
        if (slot.bytes != null && slot.file != null) {
          final uploaded = await InspectionService.uploadPhoto(
            slot.bytes!,
            slot.file!.name,
          );
          if (uploaded != null && uploaded.isNotEmpty) {
            slot.uploadedUrl = uploaded;
          }
        }

        photoUrls[slot.key] = slot.uploadedUrl ?? _getDefaultSamplePhoto(slot.key, _isCheckIn);
      }

      final odoKm = double.tryParse(_odoController.text.replaceAll(',', '.')) ?? 0.0;
      final fuelPercent = double.tryParse(_fuelController.text.replaceAll(',', '.')) ?? 100.0;

      final result = await InspectionService.submitInspection(
        bookingId: widget.bookingId,
        stage: widget.stage.toUpperCase(),
        frontImg: photoUrls['front'],
        rearImg: photoUrls['rear'],
        leftImg: photoUrls['left'],
        rightImg: photoUrls['right'],
        odoImg: photoUrls['odo'],
        fuelImg: photoUrls['fuel'],
        odoKm: odoKm,
        fuelLevelPercent: fuelPercent,
        notes: _notesController.text.trim(),
      );

      if (!mounted) return;

      if (result['success'] == true) {
        await _recordInspectionSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isCheckIn
                  ? 'Gửi biên bản nhận xe (Check-in) thành công!'
                  : 'Gửi biên bản trả xe (Check-out) thành công!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      } else {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.camera_alt, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Gửi Biên Bản', style: TextStyle(fontSize: 16)),
              ],
            ),
            content: Text(
              'Máy chủ thẩm định xe: ${result['message'] ?? 'Chưa phản hồi'}.\n\nBạn có muốn lưu biên bản này ở Chế độ Thử nghiệm (Demo) và hoàn tất không?',
              style: const TextStyle(fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  await _recordInspectionSaved();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _isCheckIn
                            ? 'Lưu biên bản nhận xe (Chế độ Thử nghiệm) thành công!'
                            : 'Lưu biên bản trả xe (Chế độ Thử nghiệm) thành công!',
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  Navigator.pop(context, true);
                },
                child: const Text('Lưu Thử nghiệm'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stageColor = _isCheckIn ? AppColors.primary : AppColors.warning;
    final stageTitle = widget.title ?? (_isCheckIn ? 'BIÊN BẢN NHẬN XE (CHECK-IN)' : 'BIÊN BẢN TRẢ XE (CHECK-OUT)');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(stageTitle),
        backgroundColor: stageColor,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header Banner Hướng dẫn quy trình
              _buildGuidanceBanner(stageColor),
              const SizedBox(height: 16),

              // 2. Lưới 6 Ô Chụp Ảnh Tiêu Chuẩn (Grid 2 cột)
              _buildPhotoGridSection(),
              const SizedBox(height: 16),

              // 3. Chỉ số ODO & Nhiên liệu
              _buildMetricsCard(),
              const SizedBox(height: 16),

              // 4. Ghi chú tình trạng xe
              _buildNotesCard(),
              const SizedBox(height: 24),

              // 5. Nút Gửi Biên Bản
              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: stageColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            widget.submitButtonText ?? (_isCheckIn ? 'GỬI BIÊN BẢN NHẬN XE' : 'GỬI BIÊN BẢN TRẢ XE'),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuidanceBanner(Color stageColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: stageColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: stageColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_rounded, color: stageColor, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isCheckIn
                      ? (widget.isOwner == true ? 'Chủ Xe Thực Hiện Giao Xe (Check-in)' : 'Nghiệp vụ Thẩm định Lúc Nhận Xe')
                      : (widget.isOwner == false ? 'Khách Thuê Hoàn Trả Xe (Check-out)' : 'Nghiệp vụ Thẩm định Lúc Trả Xe (Đối Chiếu)'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: stageColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isCheckIn
                      ? (widget.isOwner == true
                          ? 'Chủ xe chụp 6 góc ảnh hiện trạng xe, ghi nhận số ODO và lượng xăng/pin lúc bàn giao chìa khóa để gửi khách thuê kiểm tra và ký nhận.'
                          : 'Chụp 6 góc ảnh tiêu chuẩn và ghi nhận chỉ số ODO, xăng/pin ban đầu để bảo vệ quyền lợi của bạn khi trả xe.')
                      : (widget.isOwner == false
                          ? 'Người thuê chụp lại 6 góc xe lúc hoàn trả, ghi nhận số ODO và lượng xăng/pin để gửi chủ xe đối chiếu và hoàn cọc.'
                          : 'Chụp lại 6 góc xe lúc hoàn trả để hệ thống tự động so sánh đối chiếu Before/After, minh bạch cọc và tránh tranh chấp.'),
                  style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGridSection() {
    final capturedCount = _slots.where((s) => s.bytes != null).length;

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
                  Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Lưới 6 Góc Chụp Tiêu Chuẩn',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: capturedCount == 6
                      ? AppColors.success.withValues(alpha: 0.15)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$capturedCount/6 đã chụp',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: capturedCount == 6 ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Lưới 2 cột
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _slots.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              final slot = _slots[index];
              return _buildPhotoTile(slot, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoTile(_PhotoSlot slot, int index) {
    final hasImage = slot.bytes != null;

    return InkWell(
      onTap: () => _showImageSourceSheet(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: hasImage ? Colors.black87 : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasImage ? AppColors.success : AppColors.border,
            width: hasImage ? 1.5 : 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (hasImage) ...[
              Positioned.fill(
                child: Image.memory(
                  slot.bytes!,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: InkWell(
                  onTap: () => _clearImage(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 12),
                ),
              ),
            ] else ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(slot.icon, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(height: 6),
                      const Icon(Icons.add_a_photo_outlined, size: 16, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ],
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                color: Colors.black.withValues(alpha: 0.65),
                child: Text(
                  slot.title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsCard() {
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
              Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Chỉ Số Đồng Hồ & Nhiên Liệu',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _odoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Số km ODO thực tế',
                    hintText: 'VD: 15200',
                    suffixText: 'km',
                    prefixIcon: const Icon(Icons.speed_rounded, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập ODO km' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _fuelController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Mức Xăng / Pin (%)',
                    hintText: 'VD: 100',
                    suffixText: '%',
                    prefixIcon: const Icon(Icons.battery_charging_full_rounded, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập % pin/xăng' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
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
                'Ghi Chú Tình Trạng Hiện Tại Của Xe',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Mô tả vết trầy xước, mức độ vệ sinh hoặc phụ kiện bàn giao...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}
