class VietQrGenerator {
  // MB Bank BIN: 970422
  static const String mbBankBin = '970422';
  static const String defaultAccountNo = '69999968888';
  static const String defaultAccountName = 'NGUYEN THANH PHONG';

  /// Tạo chuỗi dữ liệu chuẩn EMVCo VietQR NAPAS 24/7 để tự động gen mã QR trên máy
  static String generateVietQrPayload({
    String bankBin = mbBankBin,
    String accountNumber = defaultAccountNo,
    required double amount,
    required String memo,
  }) {
    String tlv(String tag, String value) {
      final len = value.length.toString().padLeft(2, '0');
      return '$tag$len$value';
    }

    // 1. Phân hệ Tag 38: Merchant Account Information
    final guid = tlv('00', 'A000000727'); // NAPAS AID
    final bankInfo = tlv('00', bankBin) + tlv('01', accountNumber);
    final beneficiary = tlv('01', bankInfo);
    final serviceCode = tlv('02', 'QRIBFTTA'); // Chuyển nhanh 24/7 tới STK
    final tag38Value = guid + beneficiary + serviceCode;

    // 2. Phân hệ Tag 62: Additional Data (Nội dung chuyển khoản)
    final tag62Value = tlv('08', memo);

    final amountStr = amount.toInt().toString();

    // 3. Ghép chuỗi EMVCo hoàn chỉnh trước khi gắn mã kiểm tra CRC
    final rawPayload =
        tlv('00', '01') + // Phiên bản chuẩn 01
        tlv('01', '12') + // Mã động (Dynamic QR có số tiền)
        tlv('38', tag38Value) +
        tlv('53', '704') + // Tiền tệ VNĐ (704)
        tlv('54', amountStr) + // Số tiền chuyển
        tlv('58', 'VN') + // Quốc gia VN
        tlv('62', tag62Value) + // Nội dung chuyển khoản
        '6304'; // Tag CRC-16

    // 4. Tính toán mã CRC-16/CCITT (0xFFFF, 0x1021)
    final crc = _crc16(rawPayload);
    return '$rawPayload$crc';
  }

  static String _crc16(String input) {
    int crc = 0xFFFF;
    final bytes = input.codeUnits;
    for (int b in bytes) {
      crc ^= (b << 8);
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }
}

