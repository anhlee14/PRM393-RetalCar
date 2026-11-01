package com.autorental.backend.dto.request;

import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;

@Data
public class PaymentRequest {
    @NotNull(message = "ID đơn thuê không được để trống")
    @JsonAlias({"bookingId", "booking_id"})
    private Long bookingId;

    @NotNull(message = "Số tiền thanh toán không được để trống")
    private BigDecimal amount;

    @NotNull(message = "Loại thanh toán không được để trống")
    @JsonAlias({"paymentType", "payment_type"})
    private String paymentType; // DEPOSIT, FINAL_PAYMENT, REFUND

    @NotNull(message = "Phương thức thanh toán không được để trống")
    @JsonAlias({"paymentMethod", "payment_method"})
    private String paymentMethod; // CASH, BANK_TRANSFER_QR, VNPAY_MOCK
}

