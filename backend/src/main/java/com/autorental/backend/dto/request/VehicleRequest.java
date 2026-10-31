package com.autorental.backend.dto.request;

import com.autorental.backend.model.FuelType;
import com.autorental.backend.model.TransmissionType;
import com.autorental.backend.model.VehicleType;
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

    private Integer modelYear;

    @NotBlank(message = "Biển số xe không được để trống")
    private String licensePlate;

    @NotNull(message = "Loại xe không được để trống")
    private VehicleType vehicleType;

    @NotNull(message = "Loại hộp số không được để trống")
    private TransmissionType transmission;

    @NotNull(message = "Loại nhiên liệu không được để trống")
    private FuelType fuelType;

    @NotNull(message = "Giá thuê theo ngày không được để trống")
    private BigDecimal basePricePerDay;

    // Feature 1: Cấu hình có tài xế
    private Boolean hasDriverOption = false;
    private BigDecimal driverFeePerDay = BigDecimal.ZERO;

    private Integer seats = 4;
    private String description;
    private String address;

    private Double currentLat;
    private Double currentLng;

    private String thumbnailUrl;
    private List<String> imageUrls;
}

