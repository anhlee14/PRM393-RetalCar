package com.autorental.backend.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.LocalDateTime;

@Data
public class BookingRequest {
    @NotNull(message = "ID xe không được để trống")
    private Long vehicleId;

    @NotNull(message = "Ngày nhận xe không được để trống")
    private LocalDateTime startDate;

    @NotNull(message = "Ngày trả xe không được để trống")
    private LocalDateTime endDate;

    // Feature 1: Chọn thuê kèm lái xe
    private Boolean withDriver = false;

    private String pickupAddress;
    private String returnAddress;
}

