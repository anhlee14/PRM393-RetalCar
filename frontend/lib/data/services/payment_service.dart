import 'dart:convert';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';

class PaymentService {
  static Future<Map<String, dynamic>> processCheckout({
    required int bookingId,
    required double amount,
    String paymentType = 'DEPOSIT', // DEPOSIT, FINAL_PAYMENT
    required String paymentMethod, // CASH, BANK_TRANSFER_QR, VNPAY_MOCK
  }) async {
    try {
      final response = await ApiClient.post(
        ApiEndpoints.checkoutPayment,
        body: {
          'booking_id': bookingId,
          'amount': amount,
          'payment_type': paymentType,
          'payment_method': paymentMethod,
        },
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Thanh toán thất bại'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối máy chủ: $e'};
    }
  }

  static Future<List<Map<String, dynamic>>> getBookingPayments(int bookingId) async {
    try {
      final response = await ApiClient.get(ApiEndpoints.bookingPayments(bookingId));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> checkDepositStatus(int bookingId) async {
    try {
      final response = await ApiClient.get(ApiEndpoints.checkPaymentStatus(bookingId));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['success'] == true && data['data'] != null) {
          return data['data']['is_paid'] == true;
        }
      }
    } catch (_) {}
    return false;
  }
}