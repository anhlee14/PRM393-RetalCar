package com.autorental.backend.service;

import com.autorental.backend.dto.request.PaymentRequest;
import com.autorental.backend.exception.ResourceNotFoundException;
import com.autorental.backend.model.*;
import com.autorental.backend.repository.BookingRepository;
import com.autorental.backend.repository.PaymentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
@RequiredArgsConstructor
@Slf4j
public class PaymentService {

    private final PaymentRepository paymentRepository;
    private final BookingRepository bookingRepository;
    private final NotificationService notificationService;

    @Transactional
    public Payment processPayment(User user, PaymentRequest request) {
        Booking booking = bookingRepository.findById(request.getBookingId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy đơn đặt xe"));

        Payment payment = Payment.builder()
                .booking(booking)
                .user(user)
                .amount(request.getAmount())
                .paymentType(request.getPaymentType())
                .paymentMethod(request.getPaymentMethod())
                .status("SUCCESS")
                .build();

        Payment saved = paymentRepository.save(payment);

        // Gửi thông báo thanh toán
        String typeLabel = "DEPOSIT".equals(request.getPaymentType()) ? "đặt cọc (30%)" : "tiền thuê còn lại (70%)";
        notificationService.createNotification(
                booking.getVehicle().getOwner(),
                "Thanh toán " + typeLabel + " thành công",
                "Khách hàng " + user.getFullName() + " đã " + typeLabel + " " + request.getAmount() + " đ cho đơn #" + booking.getId(),
                NotificationType.PAYMENT_UPDATE,
                booking.getId()
        );

        return saved;
    }

    @Transactional(readOnly = true)
    public List<Payment> getPaymentsByBooking(Long bookingId) {
        return paymentRepository.findByBookingId(bookingId);
    }

    @Transactional(readOnly = true)
    public boolean isBookingDepositPaid(Long bookingId) {
        List<Payment> list = paymentRepository.findByBookingId(bookingId);
        return list.stream().anyMatch(p -> "DEPOSIT".equalsIgnoreCase(p.getPaymentType()) && "SUCCESS".equalsIgnoreCase(p.getStatus()));
    }

    @Transactional(readOnly = true)
    public boolean isBookingRemainingPaid(Long bookingId) {
        List<Payment> list = paymentRepository.findByBookingId(bookingId);
        return list.stream().anyMatch(p -> ("REMAINING".equalsIgnoreCase(p.getPaymentType()) || "FINAL_PAYMENT".equalsIgnoreCase(p.getPaymentType())) && "SUCCESS".equalsIgnoreCase(p.getStatus()));
    }

    @Transactional
    public Payment processBankWebhook(Map<String, Object> payload) {
        log.info("Received SePay payment webhook: {}", payload);

        // 1. Lấy thông tin nội dung chuyển khoản / mã đơn
        String content = "";
        if (payload.get("content") != null) {
            content = String.valueOf(payload.get("content"));
        } else if (payload.get("description") != null) {
            content = String.valueOf(payload.get("description"));
        } else if (payload.get("orderInvoiceNumber") != null) {
            content = String.valueOf(payload.get("orderInvoiceNumber"));
        } else if (payload.get("order_id") != null) {
            content = String.valueOf(payload.get("order_id"));
        } else if (payload.get("orderId") != null) {
            content = String.valueOf(payload.get("orderId"));
        } else if (payload.get("transactionContent") != null) {
            content = String.valueOf(payload.get("transactionContent"));
        }

        // 2. Lấy số tiền
        BigDecimal amount = BigDecimal.ZERO;
        if (payload.get("transferAmount") != null) {
            amount = new BigDecimal(String.valueOf(payload.get("transferAmount")));
        } else if (payload.get("amount") != null) {
            amount = new BigDecimal(String.valueOf(payload.get("amount")));
        } else if (payload.get("orderAmount") != null) {
            amount = new BigDecimal(String.valueOf(payload.get("orderAmount")));
        } else if (payload.get("order_amount") != null) {
            amount = new BigDecimal(String.valueOf(payload.get("order_amount")));
        }

        // 3. Phân tích mã Booking ID từ nội dung
        Long bookingId = null;
        Pattern pattern = Pattern.compile("(?i)(?:AUTORENTAL\\s+)?#?BK[-_\\s]*(\\d+)");
        Matcher matcher = pattern.matcher(content);
        if (matcher.find()) {
            bookingId = Long.parseLong(matcher.group(1));
        } else {
            // Thử trích xuất các chữ số nếu content chứa order id thuần túy
            String digits = content.replaceAll("\\D+", "");
            if (!digits.isEmpty()) {
                try {
                    bookingId = Long.parseLong(digits);
                } catch (NumberFormatException ignored) {}
            }
        }

        // 4. Nếu là test webhook từ dashboard SePay hoặc không khớp đơn nào
        if (bookingId == null) {
            log.warn("SePay Webhook: Không tìm thấy bookingId từ nội dung '{}'", content);
            return Payment.builder()
                    .paymentType("DEPOSIT")
                    .paymentMethod("SEPAY_TEST")
                    .status("SUCCESS")
                    .amount(amount)
                    .build();
        }

        Optional<Booking> bookingOpt = bookingRepository.findById(bookingId);
        if (bookingOpt.isEmpty()) {
            log.warn("SePay Webhook: Đơn đặt xe #{} không tồn tại trong hệ thống.", bookingId);
            return Payment.builder()
                    .paymentType("DEPOSIT")
                    .paymentMethod("SEPAY_TEST")
                    .status("SUCCESS")
                    .amount(amount)
                    .build();
        }

        Booking booking = bookingOpt.get();

        // 5. Kiểm tra các giao dịch thanh toán trước đó của đơn này
        List<Payment> existingPayments = paymentRepository.findByBookingId(booking.getId());
        boolean hasDeposit = existingPayments.stream()
                .anyMatch(p -> "DEPOSIT".equalsIgnoreCase(p.getPaymentType()) && "SUCCESS".equalsIgnoreCase(p.getStatus()));
        boolean hasRemaining = existingPayments.stream()
                .anyMatch(p -> ("REMAINING".equalsIgnoreCase(p.getPaymentType()) || "FINAL_PAYMENT".equalsIgnoreCase(p.getPaymentType())) && "SUCCESS".equalsIgnoreCase(p.getStatus()));

        if (hasDeposit && hasRemaining) {
            log.info("Đơn #{} đã hoàn tất thanh toán cả cọc và tiền còn lại", booking.getId());
            return existingPayments.get(0);
        }

        String paymentType = hasDeposit ? "REMAINING" : "DEPOSIT";
        String typeLabel = hasDeposit ? "tiền thuê còn lại (70%)" : "tiền cọc (30%)";

        BigDecimal defaultAmount = BigDecimal.ZERO;
        if (hasDeposit) {
            if (booking.getTotalPrice() != null && booking.getDepositAmount() != null) {
                defaultAmount = booking.getTotalPrice().subtract(booking.getDepositAmount());
            } else if (booking.getTotalPrice() != null) {
                defaultAmount = booking.getTotalPrice().multiply(BigDecimal.valueOf(0.7));
            }
        } else {
            defaultAmount = booking.getDepositAmount() != null ? booking.getDepositAmount() : BigDecimal.ZERO;
        }

        Payment payment = Payment.builder()
                .booking(booking)
                .user(booking.getRenter())
                .amount(amount.compareTo(BigDecimal.ZERO) > 0 ? amount : defaultAmount)
                .paymentType(paymentType)
                .paymentMethod("BANK_TRANSFER_QR")
                .status("SUCCESS")
                .build();

        Payment saved = paymentRepository.save(payment);

        notificationService.createNotification(
                booking.getVehicle().getOwner(),
                "Thanh toán " + typeLabel + " tự động thành công",
                "Khách hàng đã chuyển khoản " + typeLabel + " " + saved.getAmount() + " đ cho đơn #" + booking.getId(),
                NotificationType.PAYMENT_UPDATE,
                booking.getId()
        );

        log.info("Xử lý thanh toán {} SePay thành công cho đơn #{}", paymentType, booking.getId());
        return saved;
    }
}
