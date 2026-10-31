import 'dart:convert';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';

class PaymentService {
  static Future<Map<String, dynamic>> processCheckout({
    required int bookingId,
    required double amount,
    required String paymentType, // DEPOSIT, FINAL_PAYMENT
    required String paymentMethod, // CASH, BANK_TRANSFER_QR, VNPAY_MOCK
  }) async {
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
  }

  static Future<List<Map<String, dynamic>>> getBookingPayments(int bookingId) async {
    final response = await ApiClient.get(ApiEndpoints.bookingPayments(bookingId));
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data['success'] == true && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
    }
    return [];
  }
}

