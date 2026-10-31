package com.autorental.backend.dto.response;

import com.autorental.backend.model.Vehicle;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VehicleMatchResponse {
    private Vehicle vehicle;
    private Double matchScore;       // 0 to 100%
    private Double distanceKm;       // Khoảng cách tới xe
    private String matchLabel;       // "Rất phù hợp (96%)", "Phù hợp (80%)"
    private Map<String, Object> breakdownScores; // Điểm chi tiết từng tiêu chí
}

