package com.autorental.backend.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class GpsPingRequest {
    @NotNull(message = "ID đơn thuê xe không được để trống")
    private Long bookingId;

    @NotNull(message = "Vĩ độ (latitude) không được để trống")
    private Double latitude;

    @NotNull(message = "Kinh độ (longitude) không được để trống")
    private Double longitude;

    private Double speed;
}

