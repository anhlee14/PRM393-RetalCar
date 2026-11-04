package com.autorental.backend.controller;

import com.autorental.backend.dto.request.PaymentRequest;
import com.autorental.backend.dto.response.ApiResponse;
import com.autorental.backend.model.Payment;
import com.autorental.backend.model.User;
import com.autorental.backend.service.AuthService;
import com.autorental.backend.service.PaymentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/payments")
@RequiredArgsConstructor
public class PaymentController {

    private final PaymentService paymentService;
    private final AuthService authService;

    // Thanh toán / Đặt cọc
    @PostMapping("/checkout")
    public ResponseEntity<ApiResponse<Payment>> processCheckout(@Valid @RequestBody PaymentRequest request) {
        User user = authService.getCurrentUser();
        Payment payment = paymentService.processPayment(user, request);
        return ResponseEntity.ok(ApiResponse.success("Thanh toán thành công", payment));
    }

    // Lịch sử thanh toán của đơn thuê
    @GetMapping("/booking/{bookingId}")
    public ResponseEntity<ApiResponse<List<Payment>>> getBookingPayments(@PathVariable Long bookingId) {
        List<Payment> list = paymentService.getPaymentsByBooking(bookingId);
        return ResponseEntity.ok(ApiResponse.success("Lấy lịch sử thanh toán thành công", list));
    }

    // Webhook tự động nhận thông báo biến động số dư ngân hàng (SePay / Casso / SePay IPN)
    @PostMapping("/webhook")
    public ResponseEntity<ApiResponse<Payment>> handleBankWebhook(@RequestBody Map<String, Object> payload) {
        Payment payment = paymentService.processBankWebhook(payload);
        return ResponseEntity.ok(ApiResponse.success("Ghi nhận biến động số dư thành công", payment));
    }

    // Kiểm tra trạng thái cọc theo thời gian thực (Polling real-time từ mobile app)
    @GetMapping("/check-status/{bookingId}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> checkPaymentStatus(@PathVariable Long bookingId) {
        boolean isPaid = paymentService.isBookingDepositPaid(bookingId);
        return ResponseEntity.ok(ApiResponse.success("Kiểm tra trạng thái thanh toán", Map.of("is_paid", isPaid)));
    }
}
