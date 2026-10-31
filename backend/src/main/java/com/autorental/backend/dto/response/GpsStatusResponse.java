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
    private LocalDateTime lastPingTime;
    private Long minutesSinceLastPing;

    // Feature 2: Yêu cầu tối đa 1 tiếng phải bật GPS
    private Boolean isOverdue; // true nếu > 60 phút
    private String alertMessage;
}

