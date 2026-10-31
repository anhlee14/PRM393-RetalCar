package com.autorental.backend.service;

import com.autorental.backend.dto.request.PaymentRequest;
import com.autorental.backend.exception.ResourceNotFoundException;
import com.autorental.backend.model.*;
import com.autorental.backend.repository.BookingRepository;
import com.autorental.backend.repository.PaymentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
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
                .status("SUCCESS") // Giả lập thanh toán thành công
                .build();

        Payment saved = paymentRepository.save(payment);

        // Gửi thông báo thanh toán
        String typeLabel = "DEPOSIT".equals(request.getPaymentType()) ? "đặt cọc" : "thanh toán";
        notificationService.createNotification(
                booking.getVehicle().getOwner(),
                "Thanh toán " + typeLabel + " thành công",
                "Khách hàng " + user.getFullName() + " đã " + typeLabel + " " + request.getAmount() + " đ cho đơn #" + booking.getId(),
                NotificationType.PAYMENT_UPDATE,
                booking.getId()
        );

        return saved;
    }

    public List<Payment> getPaymentsByBooking(Long bookingId) {
        return paymentRepository.findByBookingId(bookingId);
    }
}

