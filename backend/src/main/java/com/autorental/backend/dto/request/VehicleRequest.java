package com.autorental.backend.dto.request;

import com.autorental.backend.model.FuelType;
import com.autorental.backend.model.TransmissionType;
import com.autorental.backend.model.VehicleType;
import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;
import java.util.List;

@Data
public class VehicleRequest {
    @NotBlank(message = "Tên xe không được để trống")
    private String name;

    @NotBlank(message = "Hãng xe không được để trống")
    private String brand;

    @JsonAlias({"modelYear", "model_year"})
    private Integer modelYear;

    @NotBlank(message = "Biển số xe không được để trống")
    @JsonAlias({"licensePlate", "license_plate"})
    private String licensePlate;

    @NotNull(message = "Loại xe không được để trống")
    @JsonAlias({"vehicleType", "vehicle_type"})
    private VehicleType vehicleType;

    @NotNull(message = "Loại hộp số không được để trống")
    private TransmissionType transmission;

    @NotNull(message = "Loại nhiên liệu không được để trống")
    @JsonAlias({"fuelType", "fuel_type"})
    private FuelType fuelType;

    @NotNull(message = "Giá thuê theo ngày không được để trống")
    @JsonAlias({"basePricePerDay", "base_price_per_day"})
    private BigDecimal basePricePerDay;

    // Feature 1: Cấu hình có tài xế
    @JsonAlias({"hasDriverOption", "has_driver_option"})
    private Boolean hasDriverOption = false;
    @JsonAlias({"driverFeePerDay", "driver_fee_per_day"})
    private BigDecimal driverFeePerDay = BigDecimal.ZERO;

    private Integer seats = 4;
    private String description;
    private String address;

    @JsonAlias({"currentLat", "current_lat"})
    private Double currentLat;
    @JsonAlias({"currentLng", "current_lng"})
    private Double currentLng;

    @JsonAlias({"thumbnailUrl", "thumbnail_url"})
    private String thumbnailUrl;
    @JsonAlias({"imageUrls", "image_urls"})
    private List<String> imageUrls;
}

