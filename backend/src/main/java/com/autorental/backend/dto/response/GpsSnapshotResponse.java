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
public class GpsSnapshotResponse {
    private Long bookingId;
    private String bookingStatus;
    private String vehicleName;
    private Double latitude;
    private Double longitude;
    private Double speed;
    private LocalDateTime recordedAt;

    // Feature 2: Giới hạn 20 lần / ngày của chủ xe
    private Integer remainingChecksToday;
    private Integer totalAllowedPerDay;
    private Boolean quotaConsumed;
}
