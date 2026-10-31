package com.autorental.backend.dto.request;

import com.autorental.backend.model.FuelType;
import com.autorental.backend.model.TransmissionType;
import com.autorental.backend.model.VehicleType;
import lombok.Data;

@Data
public class MatchingFilterRequest {
    // Tiêu chí tìm kiếm của người thuê
    private Double budget;             // Ngân sách dự kiến / ngày
    private Boolean needDriver = false;// Cần thuê cả lái xe
    private Double userLat;            // Vị trí khách
    private Double userLng;
    private VehicleType vehicleType;   // Sedan, SUV,...
    private TransmissionType transmission;
    private FuelType fuelType;

    // Trọng số điều chỉnh qua Sliders (tổng = 1.0)
    private Double budgetWeight = 0.25;
    private Double distanceWeight = 0.20;
    private Double driverWeight = 0.30;
    private Double typeWeight = 0.15;
    private Double ratingWeight = 0.10;
}

