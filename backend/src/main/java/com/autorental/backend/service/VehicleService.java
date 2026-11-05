package com.autorental.backend.service;

import com.autorental.backend.dto.request.VehicleRequest;
import com.autorental.backend.exception.BadRequestException;
import com.autorental.backend.exception.ResourceNotFoundException;
import com.autorental.backend.model.*;
import com.autorental.backend.repository.BookingRepository;
import com.autorental.backend.repository.VehicleImageRepository;
import com.autorental.backend.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class VehicleService {

    private final VehicleRepository vehicleRepository;
    private final VehicleImageRepository vehicleImageRepository;
    private final BookingRepository bookingRepository;

    @Transactional
    public Vehicle createVehicle(User owner, VehicleRequest request) {
        String normalizedPlate = request.getLicensePlate() != null
                ? request.getLicensePlate().trim().toUpperCase()
                : "";
        if (normalizedPlate.isEmpty()) {
            throw new BadRequestException("Biển số xe không được để trống!");
        }
        if (vehicleRepository.existsByLicensePlate(normalizedPlate)) {
            throw new BadRequestException("Biển số xe '" + normalizedPlate + "' đã tồn tại trên hệ thống!");
        }

        String thumbUrl = request.getThumbnailUrl();
        if ((thumbUrl == null || thumbUrl.trim().isEmpty())
                && request.getImageUrls() != null && !request.getImageUrls().isEmpty()) {
            thumbUrl = request.getImageUrls().get(0);
        }

        Vehicle vehicle = Vehicle.builder()
                .owner(owner)
                .name(request.getName().trim())
                .brand(request.getBrand().trim())
                .modelYear(request.getModelYear() != null ? request.getModelYear() : 2024)
                .licensePlate(normalizedPlate)
                .vehicleType(request.getVehicleType())
                .transmission(request.getTransmission())
                .fuelType(request.getFuelType())
                .basePricePerDay(request.getBasePricePerDay())
                // Feature 1: Cấu hình có tài xế
                .hasDriverOption(request.getHasDriverOption() != null ? request.getHasDriverOption() : false)
                .driverFeePerDay(request.getDriverFeePerDay() != null ? request.getDriverFeePerDay() : java.math.BigDecimal.ZERO)
                .seats(request.getSeats() != null ? request.getSeats() : 4)
                .description(request.getDescription())
                .address(request.getAddress())
                .currentLat(request.getCurrentLat() != null ? request.getCurrentLat() : 21.0131)
                .currentLng(request.getCurrentLng() != null ? request.getCurrentLng() : 105.5255)
                .status(VehicleStatus.PENDING_APPROVAL)
                .thumbnailUrl(thumbUrl)
                .build();

        Vehicle savedVehicle = vehicleRepository.save(vehicle);

        // Lưu danh sách ảnh phụ của xe
        if (request.getImageUrls() != null && !request.getImageUrls().isEmpty()) {
            List<VehicleImage> images = new ArrayList<>();
            for (int i = 0; i < request.getImageUrls().size(); i++) {
                String imgUrl = request.getImageUrls().get(i);
                if (imgUrl != null && !imgUrl.trim().isEmpty()) {
                    images.add(VehicleImage.builder()
                            .vehicle(savedVehicle)
                            .imageUrl(imgUrl.trim())
                            .isThumbnail(i == 0)
                            .build());
                }
            }
            if (!images.isEmpty()) {
                vehicleImageRepository.saveAll(images);
                savedVehicle.setImages(images);
            }
        }

        return savedVehicle;
    }

    @Transactional
    public Vehicle updateVehicle(Long vehicleId, User owner, VehicleRequest request) {
        Vehicle vehicle = getVehicleById(vehicleId);

        if (!vehicle.getOwner().getId().equals(owner.getId())) {
            throw new BadRequestException("Bạn không có quyền chỉnh sửa xe này!");
        }

        String normalizedPlate = request.getLicensePlate() != null
                ? request.getLicensePlate().trim().toUpperCase()
                : vehicle.getLicensePlate();
        if (vehicleRepository.existsByLicensePlateAndIdNot(normalizedPlate, vehicleId)) {
            throw new BadRequestException("Biển số xe '" + normalizedPlate + "' đã được sử dụng bởi xe khác!");
        }

        vehicle.setName(request.getName().trim());
        vehicle.setBrand(request.getBrand().trim());
        vehicle.setModelYear(request.getModelYear());
        vehicle.setLicensePlate(normalizedPlate);
        vehicle.setVehicleType(request.getVehicleType());
        vehicle.setTransmission(request.getTransmission());
        vehicle.setFuelType(request.getFuelType());
        vehicle.setBasePricePerDay(request.getBasePricePerDay());
        vehicle.setHasDriverOption(request.getHasDriverOption() != null ? request.getHasDriverOption() : false);
        vehicle.setDriverFeePerDay(request.getDriverFeePerDay() != null ? request.getDriverFeePerDay() : java.math.BigDecimal.ZERO);
        vehicle.setSeats(request.getSeats() != null ? request.getSeats() : vehicle.getSeats());
        vehicle.setDescription(request.getDescription());
        vehicle.setAddress(request.getAddress());
        if (request.getCurrentLat() != null) {
            vehicle.setCurrentLat(request.getCurrentLat());
        }
        if (request.getCurrentLng() != null) {
            vehicle.setCurrentLng(request.getCurrentLng());
        }
        if (request.getThumbnailUrl() != null) {
            vehicle.setThumbnailUrl(request.getThumbnailUrl());
        }

        if (request.getImageUrls() != null && !request.getImageUrls().isEmpty()) {
            vehicle.getImages().clear();
            for (int i = 0; i < request.getImageUrls().size(); i++) {
                String imgUrl = request.getImageUrls().get(i);
                if (imgUrl != null && !imgUrl.trim().isEmpty()) {
                    vehicle.getImages().add(VehicleImage.builder()
                            .vehicle(vehicle)
                            .imageUrl(imgUrl.trim())
                            .isThumbnail(i == 0)
                            .build());
                }
            }
        }

        return vehicleRepository.save(vehicle);
    }

    @Transactional
    public void deleteVehicle(Long vehicleId, User owner) {
        Vehicle vehicle = getVehicleById(vehicleId);

        if (!vehicle.getOwner().getId().equals(owner.getId())) {
            throw new BadRequestException("Bạn không có quyền xóa xe này!");
        }

        boolean hasActiveBookings = bookingRepository.existsByVehicleIdAndStatusIn(
                vehicleId,
                List.of(BookingStatus.PENDING, BookingStatus.CONFIRMED, BookingStatus.ONGOING)
        );
        if (hasActiveBookings) {
            throw new BadRequestException("Không thể xóa xe vì xe đang có chuyến đi hoạt động!");
        }

        vehicleRepository.delete(vehicle);
    }

    @Transactional(readOnly = true)
    public List<Vehicle> getOwnerVehicles(Long ownerId) {
        return vehicleRepository.findByOwnerId(ownerId);
    }

    @Transactional(readOnly = true)
    public List<Vehicle> getPendingVehicles() {
        return vehicleRepository.findByStatus(VehicleStatus.PENDING_APPROVAL);
    }

    @Transactional(readOnly = true)
    public List<Vehicle> getAllAvailableVehicles() {
        return vehicleRepository.findByStatus(VehicleStatus.AVAILABLE);
    }

    @Transactional(readOnly = true)
    public Vehicle getVehicleById(Long id) {
        return vehicleRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy xe với ID: " + id));
    }

    @Transactional
    public Vehicle updateVehicleStatus(Long vehicleId, VehicleStatus status) {
        Vehicle vehicle = getVehicleById(vehicleId);
        vehicle.setStatus(status);
        return vehicleRepository.save(vehicle);
    }
}
