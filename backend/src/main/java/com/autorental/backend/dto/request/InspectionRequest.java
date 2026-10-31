package com.autorental.backend.dto.request;

import com.autorental.backend.model.InspectionStage;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class InspectionRequest {
    @NotNull(message = "ID đơn đặt xe không được để trống")
    private Long bookingId;

    @NotNull(message = "Giai đoạn kiểm tra không được để trống")
    private InspectionStage stage; // CHECK_IN hoặc CHECK_OUT

    // 6 góc chụp
    private String frontImg;
    private String rearImg;
    private String leftImg;
    private String rightImg;
    private String odoImg;
    private String fuelImg;

    private Double odoKm;
    private Double fuelLevelPercent;
    private String notes;
}

