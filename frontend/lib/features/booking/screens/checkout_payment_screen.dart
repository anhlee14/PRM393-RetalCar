import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/services/payment_service.dart';
import 'booking_history_screen.dart';

class CheckoutPaymentScreen extends StatefulWidget {
  final BookingModel booking;

  const CheckoutPaymentScreen({super.key, required this.booking});

  @override
  State<CheckoutPaymentScreen> createState() => _CheckoutPaymentScreenState();
}

class _CheckoutPaymentScreenState extends State<CheckoutPaymentScreen> {
  String _selectedPaymentMethod = 'BANK_TRANSFER_QR'; // BANK_TRANSFER_QR, VNPAY_MOCK, CASH
  bool _agreedToTerms = false;
  bool _isProcessing = false;

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  String get _vietQrUrl {
    final amount = widget.booking.depositAmount.toInt();
    final addInfo = Uri.encodeComponent('AUTORENTAL BK${widget.booking.id}');
    final accountName = Uri.encodeComponent('NGUYEN VAN CHU XE');
    return 'https://img.vietqr.io/image/techcombank-190366889999-compact2.png?amount=$amount&addInfo=$addInfo&accountName=$accountName';
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
          content: Text('Vui lòng đồng ý với quy định cọc và chính sách bảo vệ xe!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final result = await PaymentService.processCheckout(
        bookingId: widget.booking.id,
        amount: widget.booking.depositAmount,
        paymentType: 'DEPOSIT',
        paymentMethod: _selectedPaymentMethod,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Thanh toán thất bại, vui lòng thử lại!'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
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
              'Thanh Toán Cọc Thành Công!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Đơn thuê #BK-${widget.booking.id} đã được ghi nhận thanh toán tiền cọc (${CurrencyFormatter.format(widget.booking.depositAmount)}). Chủ xe sẽ liên hệ bàn giao xe theo lịch hẹn!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
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
      ),
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
        title: const Text('Hóa Đơn & Đặt Cọc'),
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

            // 2. Bảng Kê Hóa Đơn Tài Chính
            _buildFinancialBreakdownCard(b, remainingAmount),
            const SizedBox(height: 16),

            // 3. Lựa chọn Phương thức Thanh toán
            _buildPaymentMethodsCard(),
            const SizedBox(height: 16),

            // 4. Checkbox Điều khoản
            _buildTermsCheckbox(),
            const SizedBox(height: 20),

            // 5. Nút bấm Xác nhận đã thanh toán cọc
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
                      children: const [
                        Icon(Icons.verified_user_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'XÁC NHẬN ĐÃ THANH TOÁN CỌC',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
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
                  children: const [
                    Text(
                      'TIỀN CỌC CẦN THANH TOÁN (30%)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.danger),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Thanh toán ngay để giữ xe',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Text(
                  CurrencyFormatter.format(b.depositAmount),
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

          // Phương thức 1: Chuyển khoản QR (VietQR)
          _buildMethodRadio(
            title: 'Chuyển khoản QR (VietQR Ngân hàng)',
            subtitle: 'Quét mã VietQR tự động điền số tiền và cú pháp',
            value: 'BANK_TRANSFER_QR',
            icon: Icons.qr_code_scanner_rounded,
          ),
          if (_selectedPaymentMethod == 'BANK_TRANSFER_QR') ...[
            const SizedBox(height: 8),
            _buildVietQrSection(),
          ],

          const Divider(height: 16),

          // Phương thức 2: MoMo / VNPay
          _buildMethodRadio(
            title: 'Ví điện tử MoMo / VNPay',
            subtitle: 'Thanh toán trực tiếp qua cổng ví điện tử',
            value: 'VNPAY_MOCK',
            icon: Icons.account_balance_rounded,
          ),

          const Divider(height: 16),

          // Phương thức 3: Tiền mặt khi nhận xe
          _buildMethodRadio(
            title: 'Tiền mặt khi nhận bàn giao chìa khóa',
            subtitle: 'Thanh toán trực tiếp cho chủ xe khi nhận xe',
            value: 'CASH',
            icon: Icons.payments_rounded,
          ),
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
      onTap: () => setState(() => _selectedPaymentMethod = value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _selectedPaymentMethod,
              onChanged: (val) {
                if (val != null) setState(() => _selectedPaymentMethod = val);
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
    final depositInt = widget.booking.depositAmount.toInt();
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
            'QUÉT MÃ VIETQR ĐỂ CHUYỂN KHOẢN',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _vietQrUrl,
              width: 220,
              height: 220,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  width: 220,
                  height: 220,
                  color: Colors.white,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
              errorBuilder: (ctx, err, stack) => Container(
                width: 220,
                height: 220,
                color: Colors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.qr_code_2_rounded, size: 80, color: AppColors.primary),
                    SizedBox(height: 8),
                    Text(
                      'Mã QR Chuyển khoản',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
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
                _buildBankInfoRow('Ngân hàng:', 'Techcombank'),
                const SizedBox(height: 6),
                _buildBankInfoRow('Chủ tài khoản:', 'NGUYEN VAN CHU XE'),
                const SizedBox(height: 6),
                _buildBankInfoRow('Số tài khoản:', '190366889999', isCopyable: true),
                const SizedBox(height: 6),
                _buildBankInfoRow('Số tiền cọc:', CurrencyFormatter.format(depositInt)),
                const SizedBox(height: 6),
                _buildBankInfoRow('Nội dung CK:', contentSyntax, isCopyable: true),
              ],
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Sao chép STK & Nội dung', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              _copyToClipboard('190366889999\n$contentSyntax', 'Đã sao chép Số tài khoản và Nội dung chuyển khoản!');
            },
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
              onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
              activeColor: AppColors.primary,
            ),
            const Expanded(
              child: Text(
                'Tôi đồng ý với quy định cọc 30% và chính sách bảo vệ xe của AutoRental.',
                style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
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
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor ?? AppColors.textPrimary),
        ),
      ],
    );
  }
}
