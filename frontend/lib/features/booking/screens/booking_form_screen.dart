import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/vehicle_image_helper.dart';
import '../../../data/models/vehicle_model.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/services/booking_service.dart';
import 'checkout_payment_screen.dart';

class BookingFormScreen extends StatefulWidget {
  final VehicleModel vehicle;

  const BookingFormScreen({super.key, required this.vehicle});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _startDate;
  late DateTime _endDate;
  bool _withDriver = false;
  late final TextEditingController _pickupController;
  late final TextEditingController _returnController;
  bool _isLoading = false;

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day + 1, 8, 0);
    _endDate = DateTime(now.year, now.month, now.day + 3, 20, 0);

    final defaultAddress = widget.vehicle.address ?? 'Hà Nội';
    _pickupController = TextEditingController(text: defaultAddress);
    _returnController = TextEditingController(text: defaultAddress);
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _returnController.dispose();
    super.dispose();
  }

  int get _rentalDays {
    final diff = _endDate.difference(_startDate).inDays;
    return diff <= 0 ? 1 : diff;
  }

  double get _carPriceTotal => widget.vehicle.basePricePerDay * _rentalDays;
  double get _driverPriceTotal =>
      (_withDriver && widget.vehicle.hasDriverOption) ? widget.vehicle.driverFeePerDay * _rentalDays : 0.0;
  double get _totalPrice => _carPriceTotal + _driverPriceTotal;
  double get _depositAmount => _totalPrice * 0.30;

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initialRange = DateTimeRange(
      start: _startDate.isBefore(now) ? now : _startDate,
      end: _endDate,
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
      initialDateRange: initialRange,
      helpText: 'CHỌN THỜI GIAN THUÊ XE',
      cancelText: 'HỦY',
      confirmText: 'CHỌN',
      saveText: 'XÁC NHẬN',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await BookingService.createBooking(
        vehicleId: widget.vehicle.id,
        startDate: _startDate,
        endDate: _endDate,
        withDriver: _withDriver && widget.vehicle.hasDriverOption,
        pickupAddress: _pickupController.text.trim(),
        returnAddress: _returnController.text.trim(),
      );

      if (!mounted) return;

      if (result['success'] == true && result['data'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tạo yêu cầu thuê xe thành công!'),
            backgroundColor: AppColors.success,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CheckoutPaymentScreen(booking: result['data']),
          ),
        );
      } else {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Kết Nối Máy Chủ', style: TextStyle(fontSize: 16)),
              ],
            ),
            content: Text(
              'Máy chủ backend phản hồi: ${result['message'] ?? 'Chưa phản hồi'}.\n\nBạn có muốn tiếp tục sang màn Thanh toán Cọc (Chế độ Thử nghiệm / Demo) với các thông tin đã chọn không?',
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
                onPressed: () {
                  Navigator.pop(ctx);
                  final mockBooking = BookingModel(
                    id: 999,
                    vehicle: widget.vehicle,
                    startDate: _startDate.toIso8601String(),
                    endDate: _endDate.toIso8601String(),
                    withDriver: _withDriver && widget.vehicle.hasDriverOption,
                    carRentalPrice: _carPriceTotal,
                    driverServicePrice: _driverPriceTotal,
                    totalPrice: _totalPrice,
                    depositAmount: _depositAmount,
                    status: 'PENDING',
                    pickupAddress: _pickupController.text.trim(),
                    returnAddress: _returnController.text.trim(),
                  );
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CheckoutPaymentScreen(booking: mockBooking),
                    ),
                  );
                },
                child: const Text('Tiếp tục thử nghiệm'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    final thumbnailUrl = VehicleImageHelper.getThumbnail(v);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cấu Hình Đặt Xe'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Thẻ Tóm tắt xe
              _buildVehicleSummaryCard(v, thumbnailUrl),
              const SizedBox(height: 16),

              // 2. Bộ chọn Thời gian thuê xe
              _buildDateRangePickerCard(),
              const SizedBox(height: 16),

              // 3. Tuỳ chọn Nghiệp vụ 1: Thuê kèm tài xế riêng
              _buildDriverOptionCard(v),
              const SizedBox(height: 16),

              // 4. Địa điểm nhận & trả xe
              _buildLocationCard(),
              const SizedBox(height: 16),

              // 5. Bảng Tạm tính Chi phí Thời gian thực
              _buildPriceBreakdownCard(v),
              const SizedBox(height: 24),

              // 6. Nút tiếp tục thanh toán cọc
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.payment_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'TIẾP TỤC ĐẾN THANH TOÁN CỌC',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
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

  Widget _buildVehicleSummaryCard(VehicleModel v, String thumbnailUrl) {
    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              thumbnailUrl,
              width: 90,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => Container(
                width: 90,
                height: 70,
                color: Colors.grey.shade200,
                child: const Icon(Icons.directions_car, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        v.licensePlate,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• ${v.brand}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    text: CurrencyFormatter.format(v.basePricePerDay),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                    children: const [
                      TextSpan(
                        text: ' /ngày',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangePickerCard() {
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
                  Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Thời gian thuê xe',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_rentalDays ngày',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDateRange,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ngày nhận xe', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                          _dateFormat.format(_startDate),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, color: AppColors.textSecondary, size: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Ngày trả xe', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                          _dateFormat.format(_endDate),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.edit_calendar_outlined, color: AppColors.primary, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverOptionCard(VehicleModel v) {
    final supportsDriver = v.hasDriverOption;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _withDriver && supportsDriver ? AppColors.accent : AppColors.border,
          width: _withDriver && supportsDriver ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: supportsDriver ? AppColors.accent.withValues(alpha: 0.15) : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_pin_circle_rounded,
                  color: supportsDriver ? AppColors.accent : Colors.grey,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thuê kèm tài xế riêng',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      supportsDriver
                          ? '+${CurrencyFormatter.format(v.driverFeePerDay)} /ngày'
                          : 'Xe này chủ xe chỉ cho thuê tự lái',
                      style: TextStyle(
                        fontSize: 12,
                        color: supportsDriver ? AppColors.accent : AppColors.textSecondary,
                        fontWeight: supportsDriver ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: supportsDriver ? _withDriver : false,
                onChanged: supportsDriver
                    ? (val) {
                        setState(() => _withDriver = val);
                      }
                    : null,
                activeColor: AppColors.accent,
              ),
            ],
          ),
          if (supportsDriver && _withDriver) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, size: 16, color: AppColors.accent),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tài xế chuyên nghiệp, lịch sự, am hiểu lộ trình sẽ đón bạn đúng hẹn.',
                      style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
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

  Widget _buildLocationCard() {
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
              Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Địa điểm bàn giao & hoàn trả',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _pickupController,
            decoration: InputDecoration(
              labelText: 'Địa điểm nhận xe',
              prefixIcon: const Icon(Icons.flight_takeoff_rounded, color: AppColors.primary, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập địa điểm nhận xe' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _returnController,
            decoration: InputDecoration(
              labelText: 'Địa điểm trả xe',
              prefixIcon: const Icon(Icons.flight_land_rounded, color: AppColors.success, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập địa điểm trả xe' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdownCard(VehicleModel v) {
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
              Icon(Icons.calculate_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Bảng Tạm Tính Chi Phí',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildPriceRow(
            'Tiền thuê xe (${CurrencyFormatter.format(v.basePricePerDay)} x $_rentalDays ngày)',
            CurrencyFormatter.format(_carPriceTotal),
          ),
          if (_withDriver && v.hasDriverOption) ...[
            const SizedBox(height: 8),
            _buildPriceRow(
              'Phụ phí tài xế riêng (${CurrencyFormatter.format(v.driverFeePerDay)} x $_rentalDays ngày)',
              CurrencyFormatter.format(_driverPriceTotal),
              textColor: AppColors.accent,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          _buildPriceRow(
            'TỔNG CHI PHÍ CHUYẾN ĐI',
            CurrencyFormatter.format(_totalPrice),
            isBold: true,
            fontSize: 15,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'TIỀN CỌC CẦN THANH TOÁN (30%)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.danger),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '70% còn lại thanh toán khi nhận xe',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Text(
                  CurrencyFormatter.format(_depositAmount),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.danger),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value,
      {bool isBold = false, double fontSize = 13, Color? textColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: textColor ?? (isBold ? AppColors.textPrimary : AppColors.textSecondary),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: textColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
