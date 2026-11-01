package com.autorental.backend.dto.request;

import com.autorental.backend.model.InspectionStage;
import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class InspectionRequest {
    @NotNull(message = "ID đơn đặt xe không được để trống")
    @JsonAlias({"bookingId", "booking_id"})
    private Long bookingId;

    @NotNull(message = "Giai đoạn kiểm tra không được để trống")
    private InspectionStage stage; // CHECK_IN hoặc CHECK_OUT

    // 6 góc chụp
    @JsonAlias({"frontImg", "front_img"})
    private String frontImg;
    @JsonAlias({"rearImg", "rear_img"})
    private String rearImg;
    @JsonAlias({"leftImg", "left_img"})
    private String leftImg;
    @JsonAlias({"rightImg", "right_img"})
    private String rightImg;
    @JsonAlias({"odoImg", "odo_img"})
    private String odoImg;
    @JsonAlias({"fuelImg", "fuel_img"})
    private String fuelImg;

    @JsonAlias({"odoKm", "odo_km"})
    private Double odoKm;
    @JsonAlias({"fuelLevelPercent", "fuel_level_percent"})
    private Double fuelLevelPercent;
    private String notes;
}

