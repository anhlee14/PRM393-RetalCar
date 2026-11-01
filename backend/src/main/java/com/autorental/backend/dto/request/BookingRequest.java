package com.autorental.backend.dto.request;

import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.LocalDateTime;

@Data
public class BookingRequest {
    @NotNull(message = "ID xe không được để trống")
    @JsonAlias({"vehicleId", "vehicle_id"})
    private Long vehicleId;

    @NotNull(message = "Ngày nhận xe không được để trống")
    @JsonAlias({"startDate", "start_date"})
    private LocalDateTime startDate;

    @NotNull(message = "Ngày trả xe không được để trống")
    @JsonAlias({"endDate", "end_date"})
    private LocalDateTime endDate;

    // Feature 1: Chọn thuê kèm lái xe
    @JsonAlias({"withDriver", "with_driver"})
    private Boolean withDriver = false;

    @JsonAlias({"pickupAddress", "pickup_address"})
    private String pickupAddress;

    @JsonAlias({"returnAddress", "return_address"})
    private String returnAddress;
}

