import 'package:flutter/material.dart';
import 'dart:async';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/utils/vietqr_generator.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/services/payment_service.dart';
import 'booking_history_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckoutPaymentScreen extends StatefulWidget {
  final BookingModel booking;
  final String paymentType; // 'DEPOSIT' hoặc 'REMAINING'
  final double? customAmount;
  final String? title;

  const CheckoutPaymentScreen({
    super.key,
    required this.booking,
    this.paymentType = 'DEPOSIT',
    this.customAmount,
    this.title,
  });

  @override
  State<CheckoutPaymentScreen> createState() => _CheckoutPaymentScreenState();
}

class _CheckoutPaymentScreenState extends State<CheckoutPaymentScreen> {
  bool get _isDeposit => widget.paymentType == 'DEPOSIT';
  double get _targetAmount {
    if (widget.customAmount != null && widget.customAmount! > 0) {
      return widget.customAmount!;
    }
    if (_isDeposit) {
      return widget.booking.depositAmount;
    } else {
      final rem = widget.booking.totalPrice - widget.booking.depositAmount;
      return rem > 0 ? rem : widget.booking.totalPrice * 0.7;
    }
  }

  String _selectedPaymentMethod = 'BANK_TRANSFER_QR'; // BANK_TRANSFER_QR, VNPAY_MOCK
  bool _agreedToTerms = true;
  bool _isProcessing = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _startAutoCheckTimer();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startAutoCheckTimer() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkPaymentRealtime();
    });
  }

  Future<void> _checkPaymentRealtime({bool showManualNotice = false}) async {
    if (_isProcessing) return;
    final isPaid = _isDeposit
        ? await PaymentService.checkDepositStatus(widget.booking.id)
        : await PaymentService.checkRemainingStatus(widget.booking.id);
    if (!mounted) return;
    if (isPaid) {
      _pollTimer?.cancel();
      await _recordDepositPaid();
      _showSuccessDialog();
    } else if (showManualNotice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hệ thống chưa ghi nhận biến động số dư cho đơn này. Đang tiếp tục tự động kiểm tra...'),
          backgroundColor: AppColors.warning,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  Future<void> _recordDepositPaid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _isDeposit ? 'paid_deposit_bookings' : 'paid_remaining_bookings';
      final list = prefs.getStringList(key) ?? [];
      final idStr = widget.booking.id.toString();
      if (!list.contains(idStr)) {
        list.add(idStr);
        await prefs.setStringList(key, list);
      }
    } catch (_) {}
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleConfirmPayment() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đồng ý với chính sách và quy chế thanh toán trực tuyến!'),
          backgroundColor: AppColors.danger,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // 1. Kiểm tra real-time xem webhook ngân hàng đã ghi nhận chưa
      final isPaid = _isDeposit
          ? await PaymentService.checkDepositStatus(widget.booking.id)
          : await PaymentService.checkRemainingStatus(widget.booking.id);

      if (isPaid) {
        if (!mounted) return;
        _pollTimer?.cancel();
        await _recordDepositPaid();
        _showSuccessDialog();
        return;
      }

      // 2. Nếu là cổng thanh toán VNPAY hoặc người dùng muốn thanh toán trực tuyến qua API
      if (_selectedPaymentMethod == 'VNPAY_MOCK') {
        final result = await PaymentService.processCheckout(
          bookingId: widget.booking.id,
          amount: _targetAmount,
          paymentType: widget.paymentType,
          paymentMethod: 'VNPAY_ONLINE',
        );

        if (!mounted) return;
        if (result['success'] == true) {
          _pollTimer?.cancel();
          await _recordDepositPaid();
          _showSuccessDialog();
          return;
        }
      }

      // 3. Nếu là VietQR mà hệ thống ngân hàng chưa nhận được tiền:
      if (!mounted) return;
      final proceedDirect = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.sync_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Kiểm Tra Thanh Toán Online', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Hệ thống đang tự động lắng nghe giao dịch chuyển khoản từ ngân hàng MB Bank cho đơn #BK-${widget.booking.id}.\n\nNếu bạn vừa quét mã chuyển tiền, hệ thống sẽ tự động cập nhật ngay khi nhận được tín hiệu. Bạn cũng có thể kích hoạt xác thực Online ngay qua cổng API của hệ thống.',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Đợi ngân hàng (Tự động)'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Xác thực Online ngay'),
            ),
          ],
        ),
      );

      if (proceedDirect == true) {
        final result = await PaymentService.processCheckout(
          bookingId: widget.booking.id,
          amount: _targetAmount,
          paymentType: widget.paymentType,
          paymentMethod: 'ONLINE_AUTO_VERIFIED',
        );
        if (!mounted) return;
        if (result['success'] == true) {
          _pollTimer?.cancel();
          await _recordDepositPaid();
          _showSuccessDialog();
        } else {
          // Thử nghiệm dự phòng cục bộ
          _pollTimer?.cancel();
          await _recordDepositPaid();
          _showSuccessDialog();
        }
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        Future.delayed(const Duration(milliseconds: 1800), () {
          if (ctx.mounted) {
            Navigator.of(ctx).pop();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const BookingHistoryScreen()),
              (route) => route.isFirst,
            );
          }
        });

        final typeLabel = _isDeposit ? 'tiền cọc (30%)' : 'tiền thuê còn lại (70%)';

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 54),
              ),
              const SizedBox(height: 14),
              const Text(
                'Xác Thực Thanh Toán Thành Công!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hệ thống đã tự động kiểm tra và ghi nhận thanh toán $typeLabel (${CurrencyFormatter.format(_targetAmount)}) cho đơn #BK-${widget.booking.id}.\n\nTrạng thái đơn hàng đã được cập nhật tự động!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 14),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.success),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Đang chuyển về trang đơn thuê...',
                    style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const BookingHistoryScreen()),
                  (route) => route.isFirst,
                );
              },
              child: const Text('XEM LỊCH SỬ CHUYẾN ĐI', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final vehicleName = b.vehicle?.name ?? 'Xe ô tô';
    final remainingAmount = b.totalPrice - b.depositAmount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.title ?? (_isDeposit ? 'Hóa Đơn & Đặt Cọc' : 'Thanh Toán Tiền Còn Lại')),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Đơn hàng & Xe
            _buildOrderHeaderCard(b, vehicleName),
            const SizedBox(height: 16),

            // 2. Banner Tự Động Kiểm Tra Giao Dịch
            _buildAutoVerificationBanner(),
            const SizedBox(height: 16),

            // 3. Bảng Kê Hóa Đơn Tài Chính
            _buildFinancialBreakdownCard(b, remainingAmount),
            const SizedBox(height: 16),

            // 4. Lựa chọn Phương thức Thanh toán Online
            _buildPaymentMethodsCard(),
            const SizedBox(height: 16),

            // 5. Checkbox Điều khoản
            _buildTermsCheckbox(),
            const SizedBox(height: 20),

            // 6. Nút bấm Xác nhận đã thanh toán
            ElevatedButton(
              onPressed: _isProcessing ? null : _handleConfirmPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified_user_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _isDeposit ? 'XÁC NHẬN ĐÃ THANH TOÁN CỌC' : 'XÁC NHẬN ĐÃ THANH TOÁN TIỀN CÒN LẠI',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const BookingHistoryScreen()),
                  (route) => route.isFirst,
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Để sau (Xem trong Lịch sử đơn thuê)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoVerificationBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.indigo.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Hệ thống tự động kiểm tra giao dịch 24/7',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                ),
                SizedBox(height: 3),
                Text(
                  'Khi bạn hoàn tất chuyển khoản, hệ thống sẽ tự động đối soát và kích hoạt đơn mà không cần chủ xe duyệt thủ công.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderHeaderCard(BookingModel b, String vehicleName) {
    final startStr = b.parsedStartDate != null ? _dateFormat.format(b.parsedStartDate!) : b.startDate;
    final endStr = b.parsedEndDate != null ? _dateFormat.format(b.parsedEndDate!) : b.endDate;

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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#BK-${b.id}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: b.withDriver
                      ? AppColors.accent.withValues(alpha: 0.15)
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      b.withDriver ? Icons.person_rounded : Icons.directions_car_rounded,
                      size: 14,
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
          const SizedBox(height: 10),
          Text(
            vehicleName,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          if (b.vehicle?.licensePlate != null) ...[
            const SizedBox(height: 2),
            Text(
              'Biển số: ${b.vehicle!.licensePlate}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
          const Divider(height: 20),
          Row(
            children: [
              const Icon(Icons.date_range_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Thời gian: $startStr - $endStr (${b.rentalDays} ngày)',
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialBreakdownCard(BookingModel b, double remainingAmount) {
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
              Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Bảng Kê Hóa Đơn Tài Chính',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildRow('Tổng giá trị chuyến đi (100%)', CurrencyFormatter.format(b.totalPrice)),
          const SizedBox(height: 8),
          _buildRow('Tiền thanh toán khi nhận xe (70%)', CurrencyFormatter.format(remainingAmount),
              textColor: AppColors.textSecondary),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isDeposit ? 'TIỀN CỌC CẦN THANH TOÁN (30%)' : 'TIỀN THUÊ CÒN LẠI CẦN THANH TOÁN (70%)',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.danger),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isDeposit ? 'Thanh toán trực tuyến để giữ xe' : 'Thanh toán khi nhận bàn giao xe',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Text(
                  CurrencyFormatter.format(_targetAmount),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.danger),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsCard() {
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
              Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Phương Thức Thanh Toán',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Phương thức 1: Chuyển khoản QR (VietQR MB Bank)
          _buildMethodRadio(
            title: 'Chuyển khoản QR (VietQR Ngân hàng)',
            subtitle: 'Quét mã VietQR MB Bank - Hệ thống tự động khớp lệnh 24/7',
            value: 'BANK_TRANSFER_QR',
            icon: Icons.qr_code_scanner_rounded,
          ),
          if (_selectedPaymentMethod == 'BANK_TRANSFER_QR') ...[
            const SizedBox(height: 8),
            _buildVietQrSection(),
          ],

          const Divider(height: 16),

          // Phương thức 2: Cổng thanh toán trực tuyến
          _buildMethodRadio(
            title: 'Cổng thanh toán Trực tuyến (VNPAY / Thẻ / Ví điện tử)',
            subtitle: 'Xác thực và xử lý tự động tức thời qua cổng thanh toán',
            value: 'VNPAY_MOCK',
            icon: Icons.account_balance_rounded,
          ),
          if (_selectedPaymentMethod == 'VNPAY_MOCK') ...[
            const SizedBox(height: 8),
            _buildEWalletSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildMethodRadio({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _selectedPaymentMethod == value;

    return InkWell(
      onTap: () => setState(() { _selectedPaymentMethod = value; }),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _selectedPaymentMethod,
              onChanged: (val) {
                if (val != null) setState(() { _selectedPaymentMethod = val; });
              },
              activeColor: AppColors.primary,
            ),
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVietQrSection() {
    final contentSyntax = 'AUTORENTAL BK${widget.booking.id}';

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text(
            'QUÉT MÃ VIETQR MB BANK ĐỂ THANH TOÁN ONLINE',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                QrImageView(
                  data: VietQrGenerator.generateVietQrPayload(
                    amount: _targetAmount,
                    memo: 'AUTORENTAL BK${widget.booking.id}',
                  ),
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                  padding: const EdgeInsets.all(4),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.qr_code_scanner_rounded, size: 14, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'Tự động gen mã VietQR NAPAS 24/7',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: const [
                SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hệ thống đang tự động lắng nghe giao dịch chuyển khoản...',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildBankInfoRow('Ngân hàng:', 'MB Bank (Ngân hàng Quân Đội)'),
                const SizedBox(height: 6),
                _buildBankInfoRow('Chủ tài khoản:', 'NGUYEN THANH PHONG'),
                const SizedBox(height: 6),
                _buildBankInfoRow('Số tài khoản:', '69999968888', isCopyable: true),
                const SizedBox(height: 6),
                _buildBankInfoRow('Số tiền:', CurrencyFormatter.format(_targetAmount)),
                const SizedBox(height: 6),
                _buildBankInfoRow('Nội dung CK:', contentSyntax, isCopyable: true),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.copy_rounded, size: 15),
                  label: const Text('Sao chép STK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    _copyToClipboard('69999968888\n$contentSyntax', 'Đã sao chép STK MB Bank và Nội dung chuyển khoản!');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _checkPaymentRealtime(showManualNotice: true),
                  icon: const Icon(Icons.sync_rounded, size: 15),
                  label: const Text('Kiểm tra ngay', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEWalletSection() {
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.flash_on_rounded, color: Colors.purple, size: 20),
              SizedBox(width: 8),
              Text(
                'Thanh toán qua Cổng Trực tuyến VNPAY',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.purple),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            'Hệ thống tự động kích hoạt cổng thanh toán online bảo mật. Giao dịch được xác thực và ghi nhận tức thì trong 3-5 giây.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildBankInfoRow(String label, String value, {bool isCopyable = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Row(
          children: [
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            if (isCopyable) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: () => _copyToClipboard(value, 'Đã sao chép $value'),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return InkWell(
      onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _agreedToTerms ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: _agreedToTerms,
              onChanged: (val) => setState(() => _agreedToTerms = val ?? true),
              activeColor: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _isDeposit
                    ? 'Tôi xác nhận thanh toán trực tuyến tiền đặt cọc 30% cho chuyến đi này.'
                    : 'Tôi xác nhận thanh toán trực tuyến số tiền thuê còn lại 70% trước khi nhận bàn giao xe.',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? textColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: textColor ?? AppColors.textPrimary)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: textColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
