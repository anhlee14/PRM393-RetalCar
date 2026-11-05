package com.autorental.backend.service;

import com.autorental.backend.model.Booking;
import com.autorental.backend.model.BookingStatus;
import com.autorental.backend.model.NotificationType;
import com.autorental.backend.repository.BookingRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
@Slf4j
@RequiredArgsConstructor
public class GpsMonitorScheduler {

    private final BookingRepository bookingRepository;
    private final NotificationService notificationService;

    // Lưu mốc thời gian gửi cảnh báo gần nhất của từng Booking để chống spam thông báo mỗi 15 phút
    private final Map<Long, LocalDateTime> lastAlertSentAt = new ConcurrentHashMap<>();

    // Chạy định kỳ mỗi 15 phút để quét các xe đang trong chuyến đi (ONGOING)
    @Scheduled(fixedRate = 900000) // 15 phút = 900,000 ms
    public void checkOverdueGpsPings() {
        List<Booking> ongoingBookings = bookingRepository.findByStatus(BookingStatus.ONGOING);

        for (Booking booking : ongoingBookings) {
            // Nếu đơn thuê có tài xế của chủ xe lái, không phạt khách thuê vi phạm GPS
            if (Boolean.TRUE.equals(booking.getWithDriver())) {
                continue;
            }

            LocalDateTime lastPing = booking.getLastRenterGpsPing();
            boolean isOverdue = false;
            long minutes = 0;

            if (lastPing == null) {
                isOverdue = true;
            } else {
                minutes = ChronoUnit.MINUTES.between(lastPing, LocalDateTime.now());
                if (minutes > 60) {
                    isOverdue = true;
                } else {
                    // Khách đã ping lại GPS -> Xóa khỏi danh sách hạn chế gửi cảnh báo
                    lastAlertSentAt.remove(booking.getId());
                }
            }

            if (isOverdue) {
                LocalDateTime lastAlert = lastAlertSentAt.get(booking.getId());
                // Chỉ gửi thông báo lặp lại nếu đã qua ít nhất 60 phút kể từ lần cảnh báo trước
                if (lastAlert != null && ChronoUnit.MINUTES.between(lastAlert, LocalDateTime.now()) < 60) {
                    continue;
                }

                lastAlertSentAt.put(booking.getId(), LocalDateTime.now());
                String durationText = minutes > 0 ? (minutes + " phút") : "hơn 60 phút";
                log.warn("Cảnh báo: Booking #{} chưa bật GPS trong {}!", booking.getId(), durationText);

                // 1. Gửi cảnh báo cho Khách thuê
                notificationService.createNotification(
                        booking.getRenter(),
                        "Cảnh báo vi phạm quy định GPS (60 phút)",
                        "Đã " + durationText + " bạn chưa cập nhật vị trí GPS cho xe "
                                + booking.getVehicle().getName() + " (Đơn #BK-" + booking.getId()
                                + "). Vui lòng chạm để mở bản đồ và Ping GPS ngay!",
                        NotificationType.GPS_WARNING,
                        booking.getId()
                );

                // 2. Gửi thông báo cho Chủ xe biết xe đang mất tín hiệu
                if (booking.getVehicle().getOwner() != null) {
                    notificationService.createNotification(
                            booking.getVehicle().getOwner(),
                            "Xe mất tín hiệu GPS quá 60 phút",
                            "Xe " + booking.getVehicle().getName() + " (Đơn #BK-" + booking.getId()
                                    + ") đã " + durationText + " chưa nhận được tọa độ GPS mới từ khách thuê.",
                            NotificationType.GPS_WARNING,
                            booking.getId()
                    );
                }
            }
        }
    }
}
