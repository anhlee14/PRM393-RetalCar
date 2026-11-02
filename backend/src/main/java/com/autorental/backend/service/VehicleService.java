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
        Vehicle vehicle = Vehicle.builder()
                .owner(owner)
                .name(request.getName())
                .brand(request.getBrand())
                .modelYear(request.getModelYear())
                .licensePlate(request.getLicensePlate())
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
                .currentLat(request.getCurrentLat())
                .currentLng(request.getCurrentLng())
                .status(VehicleStatus.PENDING_APPROVAL)
                .thumbnailUrl(request.getThumbnailUrl())
                .build();

        Vehicle savedVehicle = vehicleRepository.save(vehicle);

        // Lưu danh sách ảnh phụ của xe
        if (request.getImageUrls() != null && !request.getImageUrls().isEmpty()) {
            List<VehicleImage> images = new ArrayList<>();
            for (int i = 0; i < request.getImageUrls().size(); i++) {
                String imgUrl = request.getImageUrls().get(i);
                images.add(VehicleImage.builder()
                        .vehicle(savedVehicle)
                        .imageUrl(imgUrl)
                        .isThumbnail(i == 0)
                        .build());
            }
            vehicleImageRepository.saveAll(images);
            savedVehicle.setImages(images);
        }

        return savedVehicle;
    }

    @Transactional
    public Vehicle updateVehicle(Long vehicleId, User owner, VehicleRequest request) {
        Vehicle vehicle = getVehicleById(vehicleId);

        if (!vehicle.getOwner().getId().equals(owner.getId())) {
            throw new BadRequestException("Bạn không có quyền chỉnh sửa xe này!");
        }

        vehicle.setName(request.getName());
        vehicle.setBrand(request.getBrand());
        vehicle.setModelYear(request.getModelYear());
        vehicle.setLicensePlate(request.getLicensePlate());
        vehicle.setVehicleType(request.getVehicleType());
        vehicle.setTransmission(request.getTransmission());
        vehicle.setFuelType(request.getFuelType());
        vehicle.setBasePricePerDay(request.getBasePricePerDay());
        vehicle.setHasDriverOption(request.getHasDriverOption() != null ? request.getHasDriverOption() : false);
        vehicle.setDriverFeePerDay(request.getDriverFeePerDay() != null ? request.getDriverFeePerDay() : java.math.BigDecimal.ZERO);
        vehicle.setSeats(request.getSeats() != null ? request.getSeats() : vehicle.getSeats());
        vehicle.setDescription(request.getDescription());
        vehicle.setAddress(request.getAddress());
        vehicle.setCurrentLat(request.getCurrentLat());
        vehicle.setCurrentLng(request.getCurrentLng());
        if (request.getThumbnailUrl() != null) {
            vehicle.setThumbnailUrl(request.getThumbnailUrl());
        }

        if (request.getImageUrls() != null && !request.getImageUrls().isEmpty()) {
            vehicle.getImages().clear();
            for (int i = 0; i < request.getImageUrls().size(); i++) {
                String imgUrl = request.getImageUrls().get(i);
                vehicle.getImages().add(VehicleImage.builder()
                        .vehicle(vehicle)
                        .imageUrl(imgUrl)
                        .isThumbnail(i == 0)
                        .build());
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
