package com.autorental.backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GpsStatusResponse {
    private Long bookingId;
    private String bookingStatus;
    private String vehicleName;
    private Boolean withDriver;
    private LocalDateTime lastPingTime;
    private Long minutesSinceLastPing;

    // Feature 2: Yêu cầu tối đa 1 tiếng phải bật GPS (chỉ áp dụng khi đơn đang ONGOING)
    private Boolean isOverdue; // true nếu ONGOING và > 60 phút
    private String alertMessage;

    // Thông tin Quota hiện tại (cho phép Chủ xe xem số lượt còn lại mà không bị trừ lượt)
    private Integer remainingChecksToday;
    private Integer totalAllowedPerDay;
    private Boolean canPing;
    private Boolean canOwnerCheckSnapshot;
}
