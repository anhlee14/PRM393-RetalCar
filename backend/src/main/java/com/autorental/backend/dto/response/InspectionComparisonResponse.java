package com.autorental.backend.dto.response;

import com.autorental.backend.model.Inspection;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InspectionComparisonResponse {
    private Long bookingId;
    private String vehicleName;
    private String licensePlate;

    // Ảnh ban đầu lúc giao nhận
    private Inspection checkIn;

    // Ảnh chụp mới lúc hoàn trả
    private Inspection checkOut;

    // Chênh lệch số km và mức nhiên liệu
    private Double odoDifferenceKm;
    private Double fuelDifferencePercent;

    // Trạng thái xác nhận 2 bên
    private Boolean isFullyConfirmed;
}

