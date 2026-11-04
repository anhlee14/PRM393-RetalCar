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

    // Feature 2: Người thuê gửi toạ độ hiện tại (Tối đa 1 tiếng phải gửi 1 lần khi đơn đang ONGOING)
    @Transactional
    public GpsLog recordPing(GpsPingRequest request, User currentUser) {
        Booking booking = bookingRepository.findById(request.getBookingId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy đơn đặt xe #" + request.getBookingId()));

        // 1. Kiểm tra quyền gửi tín hiệu GPS (Chỉ khách thuê của đơn này, hoặc chủ xe/tài xế nếu đơn có tài xế)
        if (currentUser != null) {
            boolean isRenter = booking.getRenter() != null && booking.getRenter().getId().equals(currentUser.getId());
            boolean isOwnerDriver = Boolean.TRUE.equals(booking.getWithDriver())
                    && booking.getVehicle() != null
                    && booking.getVehicle().getOwner() != null
                    && booking.getVehicle().getOwner().getId().equals(currentUser.getId());

            if (!isRenter && !isOwnerDriver) {
                throw new BadRequestException("Bạn không có quyền gửi tọa độ GPS cho chuyến xe này.");
            }
        }

        // 2. Kiểm tra trạng thái đơn thuê (Chỉ cho phép ghi nhận hành trình khi chuyến đi đang ONGOING)
        if (booking.getStatus() == BookingStatus.PENDING || booking.getStatus() == BookingStatus.CONFIRMED) {
            throw new BadRequestException("Chuyến đi chưa bắt đầu (Trạng thái: " + booking.getStatus()
                    + "). Vui lòng nhận xe và bấm 'Bắt đầu chuyến đi' để kích hoạt định vị GPS.");
        }
        if (booking.getStatus() == BookingStatus.COMPLETED || booking.getStatus() == BookingStatus.CANCELLED) {
            throw new BadRequestException("Chuyến đi đã kết thúc (Trạng thái: " + booking.getStatus()
                    + "). Hệ thống đã đóng ghi nhận GPS để bảo vệ quyền riêng tư của bạn.");
        }

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
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy đơn đặt xe #" + bookingId));

        if (!booking.getRenter().getId().equals(renterId)) {
            throw new BadRequestException("Bảo mật GDPR: Chỉ khách thuê trực tiếp của chuyến xe này mới có quyền xem toàn bộ lộ trình di chuyển (Polyline).");
        }

        return gpsLogRepository.findByBookingIdOrderByRecordedAtAsc(bookingId);
    }

    // Feature 2: Chủ xe chỉ xem Snapshot toạ độ tức thời + Giới hạn 20 lần / ngày (Tuyệt đối không xem full route)
    @Transactional
    public GpsSnapshotResponse getOwnerSnapshot(Long bookingId, User owner) {
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy đơn đặt xe #" + bookingId));

        if (!booking.getVehicle().getOwner().getId().equals(owner.getId())) {
            throw new BadRequestException("Bạn không phải chủ sở hữu xe của đơn thuê này.");
        }

        // Bảo vệ quyền riêng tư: Không cho phép chủ xe định vị trước khi giao xe hoặc sau khi khách đã trả xe
        if (booking.getStatus() == BookingStatus.PENDING || booking.getStatus() == BookingStatus.CONFIRMED) {
            throw new BadRequestException("Chuyến xe chưa khởi hành (Trạng thái: " + booking.getStatus()
                    + "). Chủ xe chỉ được phép định vị Snapshot khi chuyến đi đang diễn ra (ONGOING).");
        }
        if (booking.getStatus() == BookingStatus.COMPLETED || booking.getStatus() == BookingStatus.CANCELLED) {
            throw new BadRequestException("Hợp đồng thuê xe đã kết thúc (" + booking.getStatus()
                    + "). Chủ xe không được phép định vị khách thuê sau khi đã trả xe (Tuân thủ quyền riêng tư GDPR).");
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
            throw new QuotaExceededException("Bạn đã dùng hết " + MAX_DAILY_CHECKS
                    + " lượt kiểm tra vị trí xe trong ngày hôm nay. Hạn mức sẽ được đặt lại vào 00:00 ngày mai.");
        }

        // Tăng số lần check và lưu lại khi chủ xe chủ động bấm kiểm tra vị trí
        quota.setCheckCount(quota.getCheckCount() + 1);
        gpsQuotaRepository.save(quota);

        GpsLog latestLog = gpsLogRepository.findFirstByBookingIdOrderByRecordedAtDesc(bookingId)
                .orElse(null);

        int remaining = MAX_DAILY_CHECKS - quota.getCheckCount();

        Double lat = (latestLog != null) ? latestLog.getLatitude() : booking.getVehicle().getCurrentLat();
        Double lng = (latestLog != null) ? latestLog.getLongitude() : booking.getVehicle().getCurrentLng();
        Double speed = (latestLog != null) ? latestLog.getSpeed() : 0.0;
        LocalDateTime recordedAt = (latestLog != null)
                ? latestLog.getRecordedAt()
                : (booking.getLastRenterGpsPing() != null ? booking.getLastRenterGpsPing() : LocalDateTime.now());

        return GpsSnapshotResponse.builder()
                .bookingId(bookingId)
                .bookingStatus(booking.getStatus().name())
                .vehicleName(booking.getVehicle().getName())
                .latitude(lat)
                .longitude(lng)
                .speed(speed)
                .recordedAt(recordedAt)
                .remainingChecksToday(remaining)
                .totalAllowedPerDay(MAX_DAILY_CHECKS)
                .quotaConsumed(true)
                .build();
    }

    // Feature 2: Kiểm tra trạng thái tín hiệu GPS & số lượt Quota còn lại (Không làm trừ lượt Quota của Chủ xe)
    public GpsStatusResponse checkGpsStatus(Long bookingId) {
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy đơn đặt xe #" + bookingId));

        LocalDate today = LocalDate.now();
        Long ownerId = booking.getVehicle().getOwner().getId();
        int usedChecks = gpsQuotaRepository.findByBookingIdAndOwnerIdAndCheckDate(bookingId, ownerId, today)
                .map(GpsQuota::getCheckCount)
                .orElse(0);
        int remainingChecks = Math.max(0, MAX_DAILY_CHECKS - usedChecks);

        LocalDateTime lastPing = booking.getLastRenterGpsPing();
        long minutesDiff = 0;
        if (lastPing != null) {
            minutesDiff = Math.max(0, ChronoUnit.MINUTES.between(lastPing, LocalDateTime.now()));
        }

        BookingStatus status = booking.getStatus();
        boolean isOverdue = false;
        boolean canPing = false;
        boolean canOwnerCheckSnapshot = false;
        String alert;

        if (status == BookingStatus.ONGOING) {
            canPing = true;
            canOwnerCheckSnapshot = remainingChecks > 0;

            if (lastPing == null || minutesDiff > 60) {
                isOverdue = true;
                if (Boolean.TRUE.equals(booking.getWithDriver())) {
                    alert = "Chuyến xe có tài xế: Đã quá " + (minutesDiff > 0 ? minutesDiff + " phút" : "60 phút")
                            + " tài xế chưa đồng bộ tín hiệu GPS về hệ thống.";
                } else {
                    alert = "CẢNH BÁO VI PHẠM: Đã quá " + (minutesDiff > 0 ? minutesDiff + " phút" : "60 phút")
                            + " bạn chưa cập nhật vị trí xe. Vui lòng Ping GPS ngay để tránh vi phạm hợp đồng thuê xe!";
                }
            } else {
                alert = "Tín hiệu GPS hợp lệ (Cập nhật " + minutesDiff
                        + " phút trước). Quy định: Cập nhật tối đa mỗi 60 phút/lần.";
            }
        } else if (status == BookingStatus.PENDING || status == BookingStatus.CONFIRMED) {
            isOverdue = false;
            alert = "Chuyến xe chưa khởi hành (Trạng thái: " + status.name()
                    + "). Chế độ giám sát GPS 60 phút/lần sẽ bắt đầu ngay khi nhận xe.";
        } else {
            isOverdue = false;
            alert = "Chuyến xe đã hoàn tất (" + status.name()
                    + "). Đã ngừng giám sát GPS để bảo mật quyền riêng tư.";
        }

        return GpsStatusResponse.builder()
                .bookingId(bookingId)
                .bookingStatus(status.name())
                .vehicleName(booking.getVehicle().getName())
                .withDriver(booking.getWithDriver())
                .lastPingTime(lastPing)
                .minutesSinceLastPing(minutesDiff)
                .isOverdue(isOverdue)
                .alertMessage(alert)
                .remainingChecksToday(remainingChecks)
                .totalAllowedPerDay(MAX_DAILY_CHECKS)
                .canPing(canPing)
                .canOwnerCheckSnapshot(canOwnerCheckSnapshot)
                .build();
    }
}
