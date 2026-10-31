package com.autorental.backend.service;

import com.autorental.backend.dto.request.InspectionRequest;
import com.autorental.backend.dto.response.InspectionComparisonResponse;
import com.autorental.backend.exception.BadRequestException;
import com.autorental.backend.exception.ResourceNotFoundException;
import com.autorental.backend.model.*;
import com.autorental.backend.repository.BookingRepository;
import com.autorental.backend.repository.InspectionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class InspectionService {

    private final InspectionRepository inspectionRepository;
    private final BookingRepository bookingRepository;
    private final NotificationService notificationService;

    @Transactional
    public Inspection saveInspection(InspectionRequest request) {
        Booking booking = bookingRepository.findById(request.getBookingId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy đơn đặt xe"));

        Optional<Inspection> existing = inspectionRepository.findByBookingIdAndStage(request.getBookingId(), request.getStage());
        Inspection inspection;

        if (existing.isPresent()) {
            inspection = existing.get();
        } else {
            inspection = Inspection.builder()
                    .booking(booking)
                    .stage(request.getStage())
                    .build();
        }

        inspection.setFrontImg(request.getFrontImg());
        inspection.setRearImg(request.getRearImg());
        inspection.setLeftImg(request.getLeftImg());
        inspection.setRightImg(request.getRightImg());
        inspection.setOdoImg(request.getOdoImg());
        inspection.setFuelImg(request.getFuelImg());
        inspection.setOdoKm(request.getOdoKm());
        inspection.setFuelLevelPercent(request.getFuelLevelPercent());
        inspection.setNotes(request.getNotes());

        Inspection saved = inspectionRepository.save(inspection);

        // Gửi thông báo cho bên còn lại
        String stageLabel = request.getStage() == InspectionStage.CHECK_IN ? "bàn giao ban đầu" : "hoàn trả xe";
        notificationService.createNotification(
                booking.getRenter(),
                "Cập nhật ảnh thẩm định xe",
                "Đã có ảnh hiện trạng xe lúc " + stageLabel + ". Vui lòng kiểm tra và bấm xác nhận.",
                NotificationType.INSPECTION_UPDATE,
                booking.getId()
        );

        return saved;
    }

    @Transactional
    public Inspection confirmInspection(Long inspectionId, User user) {
        Inspection inspection = inspectionRepository.findById(inspectionId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy biên bản thẩm định"));

        Booking booking = inspection.getBooking();
        boolean isOwner = booking.getVehicle().getOwner().getId().equals(user.getId());
        boolean isRenter = booking.getRenter().getId().equals(user.getId());

        if (!isOwner && !isRenter) {
            throw new BadRequestException("Bạn không có quyền xác nhận biên bản này");
        }

        if (isOwner) {
            inspection.setIsConfirmedByOwner(true);
        }
        if (isRenter) {
            inspection.setIsConfirmedByRenter(true);
        }

        if (Boolean.TRUE.equals(inspection.getIsConfirmedByOwner()) && Boolean.TRUE.equals(inspection.getIsConfirmedByRenter())) {
            inspection.setConfirmedAt(LocalDateTime.now());
        }

        return inspectionRepository.save(inspection);
    }

    public InspectionComparisonResponse getComparison(Long bookingId) {
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy đơn đặt xe"));

        Optional<Inspection> checkInOpt = inspectionRepository.findByBookingIdAndStage(bookingId, InspectionStage.CHECK_IN);
        Optional<Inspection> checkOutOpt = inspectionRepository.findByBookingIdAndStage(bookingId, InspectionStage.CHECK_OUT);

        Inspection checkIn = checkInOpt.orElse(null);
        Inspection checkOut = checkOutOpt.orElse(null);

        Double odoDiff = 0.0;
        Double fuelDiff = 0.0;
        boolean fullyConfirmed = false;

        if (checkIn != null && checkOut != null) {
            if (checkIn.getOdoKm() != null && checkOut.getOdoKm() != null) {
                odoDiff = checkOut.getOdoKm() - checkIn.getOdoKm();
            }
            if (checkIn.getFuelLevelPercent() != null && checkOut.getFuelLevelPercent() != null) {
                fuelDiff = checkOut.getFuelLevelPercent() - checkIn.getFuelLevelPercent();
            }
            fullyConfirmed = Boolean.TRUE.equals(checkOut.getIsConfirmedByOwner()) &&
                             Boolean.TRUE.equals(checkOut.getIsConfirmedByRenter());
        }

        return InspectionComparisonResponse.builder()
                .bookingId(bookingId)
                .vehicleName(booking.getVehicle().getName())
                .licensePlate(booking.getVehicle().getLicensePlate())
                .checkIn(checkIn)
                .checkOut(checkOut)
                .odoDifferenceKm(odoDiff)
                .fuelDifferencePercent(fuelDiff)
                .isFullyConfirmed(fullyConfirmed)
                .build();
    }
}

