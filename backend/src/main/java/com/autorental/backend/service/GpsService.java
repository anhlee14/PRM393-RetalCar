package com.autorental.backend.service;

import com.autorental.backend.dto.request.GpsPingRequest;
import com.autorental.backend.dto.response.GpsSnapshotResponse;
import com.autorental.backend.dto.response.GpsStatusResponse;
import com.autorental.backend.exception.BadRequestException;
import com.autorental.backend.exception.QuotaExceededException;
import com.autorental.backend.exception.ResourceNotFoundException;
import com.autorental.backend.model.*;
import com.autorental.backend.repository.BookingRepository;
import com.autorental.backend.repository.GpsLogRepository;
import com.autorental.backend.repository.GpsQuotaRepository;
import com.autorental.backend.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;

@Service
@RequiredArgsConstructor
public class GpsService {

    private final GpsLogRepository gpsLogRepository;
    private final GpsQuotaRepository gpsQuotaRepository;
    private final BookingRepository bookingRepository;
    private final VehicleRepository vehicleRepository;

    private static final int MAX_DAILY_CHECKS = 20;

    // Feature 2: Người thuê gửi toạ độ hiện tại (Tối đa 1 tiếng phải gửi 1 lần)
    @Transactional
    public GpsLog recordPing(GpsPingRequest request) {
        Booking booking = bookingRepository.findById(request.getBookingId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy đơn đặt xe"));

        GpsLog log = GpsLog.builder()
                .booking(booking)
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .speed(request.getSpeed() != null ? request.getSpeed() : 0.0)
                .build();

        // Cập nhật vị trí hiện tại của xe
        Vehicle vehicle = booking.getVehicle();
        vehicle.setCurrentLat(request.getLatitude());
        vehicle.setCurrentLng(request.getLongitude());
        vehicleRepository.save(vehicle);

        // Cập nhật mốc thời gian ping cuối cùng của người thuê
        booking.setLastRenterGpsPing(LocalDateTime.now());
        bookingRepository.save(booking);

        return gpsLogRepository.save(log);
    }

    // Feature 2: Người thuê xem FULL lộ trình di chuyển (Polyline)
    public List<GpsLog> getRenterFullRoute(Long bookingId, Long renterId) {
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy đơn đặt xe"));

        if (!booking.getRenter().getId().equals(renterId)) {
            throw new BadRequestException("Bạn không phải người thuê của chuyến xe này");
        }

        return gpsLogRepository.findByBookingIdOrderByRecordedAtAsc(bookingId);
    }

    // Feature 2: Chủ xe chỉ xem Snapshot toạ độ tức thời + Giới hạn 20 lần / ngày (Tuyệt đối không xem full route)
    @Transactional
    public GpsSnapshotResponse getOwnerSnapshot(Long bookingId, User owner) {
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy đơn đặt xe"));

        if (!booking.getVehicle().getOwner().getId().equals(owner.getId())) {
            throw new BadRequestException("Bạn không phải chủ xe của đơn thuê này");
        }

        LocalDate today = LocalDate.now();
        GpsQuota quota = gpsQuotaRepository.findByBookingIdAndOwnerIdAndCheckDate(bookingId, owner.getId(), today)
                .orElseGet(() -> GpsQuota.builder()
                        .booking(booking)
                        .owner(owner)
                        .checkDate(today)
                        .checkCount(0)
                        .build());

        if (quota.getCheckCount() >= MAX_DAILY_CHECKS) {
            throw new QuotaExceededException("Bạn đã dùng hết " + MAX_DAILY_CHECKS + " lượt kiểm tra vị trí xe trong ngày hôm nay. Lượt check sẽ được làm mới vào ngày mai.");
        }

        // Tăng số lần check và lưu lại
        quota.setCheckCount(quota.getCheckCount() + 1);
        gpsQuotaRepository.save(quota);

        GpsLog latestLog = gpsLogRepository.findFirstByBookingIdOrderByRecordedAtDesc(bookingId)
                .orElse(null);

        int remaining = MAX_DAILY_CHECKS - quota.getCheckCount();

        Double lat = (latestLog != null) ? latestLog.getLatitude() : booking.getVehicle().getCurrentLat();
        Double lng = (latestLog != null) ? latestLog.getLongitude() : booking.getVehicle().getCurrentLng();
        Double speed = (latestLog != null) ? latestLog.getSpeed() : 0.0;
        LocalDateTime recordedAt = (latestLog != null) ? latestLog.getRecordedAt() : LocalDateTime.now();

        return GpsSnapshotResponse.builder()
                .bookingId(bookingId)
                .vehicleName(booking.getVehicle().getName())
                .latitude(lat)
                .longitude(lng)
                .speed(speed)
                .recordedAt(recordedAt)
                .remainingChecksToday(remaining)
                .totalAllowedPerDay(MAX_DAILY_CHECKS)
                .build();
    }

    // Feature 2: Kiểm tra người thuê có bật GPS trong vòng 1 tiếng không
    public GpsStatusResponse checkGpsStatus(Long bookingId) {
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy đơn đặt xe"));

        LocalDateTime lastPing = booking.getLastRenterGpsPing();
        long minutesDiff = 0;
        boolean isOverdue = false;

        if (lastPing != null) {
            minutesDiff = ChronoUnit.MINUTES.between(lastPing, LocalDateTime.now());
            if (minutesDiff > 60) {
                isOverdue = true;
            }
        } else {
            isOverdue = true;
        }

        String alert = isOverdue
                ? "Cảnh báo: Đã quá " + (minutesDiff > 0 ? minutesDiff + " phút" : "1 tiếng") + " bạn chưa cập nhật vị trí xe. Vui lòng mở GPS để tránh vi phạm quy định thuê xe!"
                : "Vị trí GPS đang được cập nhật bình thường.";

        return GpsStatusResponse.builder()
                .bookingId(bookingId)
                .lastPingTime(lastPing)
                .minutesSinceLastPing(minutesDiff)
                .isOverdue(isOverdue)
                .alertMessage(alert)
                .build();
    }
}

