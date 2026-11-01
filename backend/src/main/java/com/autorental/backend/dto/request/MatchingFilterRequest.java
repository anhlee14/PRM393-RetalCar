package com.autorental.backend.dto.request;

import com.autorental.backend.model.FuelType;
import com.autorental.backend.model.TransmissionType;
import com.autorental.backend.model.VehicleType;
import com.fasterxml.jackson.annotation.JsonAlias;
import lombok.Data;

@Data
public class MatchingFilterRequest {
    // Tiêu chí tìm kiếm của người thuê
    private Double budget;             // Ngân sách dự kiến / ngày
    @JsonAlias({"needDriver", "need_driver"})
    private Boolean needDriver = false;// Cần thuê cả lái xe
    @JsonAlias({"userLat", "user_lat"})
    private Double userLat;            // Vị trí khách
    @JsonAlias({"userLng", "user_lng"})
    private Double userLng;
    @JsonAlias({"vehicleType", "vehicle_type"})
    private VehicleType vehicleType;   // Sedan, SUV,...
    private TransmissionType transmission;
    @JsonAlias({"fuelType", "fuel_type"})
    private FuelType fuelType;

    // Trọng số điều chỉnh qua Sliders (tổng = 1.0)
    @JsonAlias({"budgetWeight", "budget_weight"})
    private Double budgetWeight = 0.25;
    @JsonAlias({"distanceWeight", "distance_weight"})
    private Double distanceWeight = 0.20;
    @JsonAlias({"driverWeight", "driver_weight"})
    private Double driverWeight = 0.30;
    @JsonAlias({"typeWeight", "type_weight"})
    private Double typeWeight = 0.15;
    @JsonAlias({"ratingWeight", "rating_weight"})
    private Double ratingWeight = 0.10;
}

