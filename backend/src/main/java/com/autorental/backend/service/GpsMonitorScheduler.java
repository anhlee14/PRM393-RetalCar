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

@Component
@Slf4j
@RequiredArgsConstructor
public class GpsMonitorScheduler {

    private final BookingRepository bookingRepository;
    private final NotificationService notificationService;

    // Chạy định kỳ mỗi 15 phút để quét các xe đang trong chuyến đi (ONGOING)
    @Scheduled(fixedRate = 900000) // 15 phút = 900,000 ms
    public void checkOverdueGpsPings() {
        List<Booking> ongoingBookings = bookingRepository.findByStatus(BookingStatus.ONGOING);

        for (Booking booking : ongoingBookings) {
            LocalDateTime lastPing = booking.getLastRenterGpsPing();
            boolean isOverdue = false;
            long minutes = 0;

            if (lastPing == null) {
                isOverdue = true;
            } else {
                minutes = ChronoUnit.MINUTES.between(lastPing, LocalDateTime.now());
                if (minutes >= 60) {
                    isOverdue = true;
                }
            }

            if (isOverdue) {
                log.warn("Cảnh báo: Booking #{} chưa bật GPS trong hơn 1 tiếng!", booking.getId());
                notificationService.createNotification(
                        booking.getRenter(),
                        "Cảnh báo vi phạm GPS",
                        "Đã hơn 1 tiếng bạn chưa bật GPS cập nhật vị trí cho xe " + booking.getVehicle().getName() + ". Vui lòng bật định vị ngay!",
                        NotificationType.GPS_WARNING,
                        booking.getId()
                );
            }
        }
    }
}

