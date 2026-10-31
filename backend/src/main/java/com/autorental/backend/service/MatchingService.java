package com.autorental.backend.service;

import com.autorental.backend.dto.request.MatchingFilterRequest;
import com.autorental.backend.dto.response.VehicleMatchResponse;
import com.autorental.backend.model.Vehicle;
import com.autorental.backend.model.VehicleStatus;
import com.autorental.backend.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class MatchingService {

    private final VehicleRepository vehicleRepository;

    public List<VehicleMatchResponse> matchVehicles(MatchingFilterRequest filter) {
        List<Vehicle> availableVehicles = vehicleRepository.findByStatus(VehicleStatus.AVAILABLE);

        // Chuẩn hóa trọng số
        double wBudget = filter.getBudgetWeight() != null ? filter.getBudgetWeight() : 0.25;
        double wDistance = filter.getDistanceWeight() != null ? filter.getDistanceWeight() : 0.20;
        double wDriver = filter.getDriverWeight() != null ? filter.getDriverWeight() : 0.30;
        double wType = filter.getTypeWeight() != null ? filter.getTypeWeight() : 0.15;
        double wRating = filter.getRatingWeight() != null ? filter.getRatingWeight() : 0.10;

        double sumWeights = wBudget + wDistance + wDriver + wType + wRating;
        if (sumWeights <= 0) sumWeights = 1.0;
        wBudget /= sumWeights;
        wDistance /= sumWeights;
        wDriver /= sumWeights;
        wType /= sumWeights;
        wRating /= sumWeights;

        List<VehicleMatchResponse> results = new ArrayList<>();

        for (Vehicle vehicle : availableVehicles) {
            // 1. Điểm tiêu chí tài xế
            double scoreDriver = 100.0;
            if (Boolean.TRUE.equals(filter.getNeedDriver())) {
                if (Boolean.TRUE.equals(vehicle.getHasDriverOption())) {
                    scoreDriver = 100.0;
                } else {
                    scoreDriver = 0.0; // Xe không hỗ trợ lái xe
                }
            }

            // 2. Điểm ngân sách
            double scoreBudget = 80.0;
            if (filter.getBudget() != null && filter.getBudget() > 0) {
                double vehicleDailyPrice = vehicle.getBasePricePerDay().doubleValue();
                if (Boolean.TRUE.equals(filter.getNeedDriver()) && Boolean.TRUE.equals(vehicle.getHasDriverOption())) {
                    vehicleDailyPrice += (vehicle.getDriverFeePerDay() != null ? vehicle.getDriverFeePerDay().doubleValue() : 0);
                }
                double diff = Math.abs(vehicleDailyPrice - filter.getBudget()) / filter.getBudget();
                if (diff <= 0.10) {
                    scoreBudget = 100.0;
                } else if (diff <= 0.25) {
                    scoreBudget = 85.0;
                } else if (diff <= 0.50) {
                    scoreBudget = 55.0;
                } else {
                    scoreBudget = Math.max(10.0, 100.0 - (diff * 100));
                }
            }

            // 3. Điểm khoảng cách (Haversine formula)
            double distanceKm = 0.0;
            double scoreDistance = 75.0;
            if (filter.getUserLat() != null && filter.getUserLng() != null &&
                vehicle.getCurrentLat() != null && vehicle.getCurrentLng() != null) {
                distanceKm = calculateHaversineDistance(
                        filter.getUserLat(), filter.getUserLng(),
                        vehicle.getCurrentLat(), vehicle.getCurrentLng()
                );
                if (distanceKm <= 3.0) {
                    scoreDistance = 100.0;
                } else if (distanceKm <= 7.0) {
                    scoreDistance = 85.0;
                } else if (distanceKm <= 15.0) {
                    scoreDistance = 65.0;
                } else if (distanceKm <= 30.0) {
                    scoreDistance = 40.0;
                } else {
                    scoreDistance = Math.max(10.0, 100.0 - (distanceKm * 2));
                }
            }

            // 4. Điểm loại xe & hộp số
            double scoreType = 0.0;
            if (filter.getVehicleType() == null || filter.getVehicleType().equals(vehicle.getVehicleType())) {
                scoreType += 50.0;
            }
            if (filter.getTransmission() == null || filter.getTransmission().equals(vehicle.getTransmission())) {
                scoreType += 30.0;
            }
            if (filter.getFuelType() == null || filter.getFuelType().equals(vehicle.getFuelType())) {
                scoreType += 20.0;
            }

            // 5. Điểm đánh giá (Rating)
            double rating = vehicle.getAverageRating() != null ? vehicle.getAverageRating() : 5.0;
            double scoreRating = (rating / 5.0) * 100.0;

            // Tính tổng điểm Matching theo trọng số
            double finalScore = (wDriver * scoreDriver) +
                               (wBudget * scoreBudget) +
                               (wDistance * scoreDistance) +
                               (wType * scoreType) +
                               (wRating * scoreRating);

            finalScore = Math.round(finalScore * 10.0) / 10.0; // Làm tròn 1 chữ số thập phân

            // Gán nhãn phù hợp
            String label;
            if (finalScore >= 90.0) {
                label = "Rất phù hợp (" + finalScore + "%)";
            } else if (finalScore >= 75.0) {
                label = "Phù hợp cao (" + finalScore + "%)";
            } else if (finalScore >= 50.0) {
                label = "Tương đối phù hợp (" + finalScore + "%)";
            } else {
                label = "Tham khảo (" + finalScore + "%)";
            }

            Map<String, Object> breakdown = new HashMap<>();
            breakdown.put("driver_score", scoreDriver);
            breakdown.put("budget_score", scoreBudget);
            breakdown.put("distance_score", scoreDistance);
            breakdown.put("type_score", scoreType);
            breakdown.put("rating_score", scoreRating);

            results.add(VehicleMatchResponse.builder()
                    .vehicle(vehicle)
                    .matchScore(finalScore)
                    .distanceKm(Math.round(distanceKm * 10.0) / 10.0)
                    .matchLabel(label)
                    .breakdownScores(breakdown)
                    .build());
        }

        // Sắp xếp giảm dần theo điểm Matching
        return results.stream()
                .sorted(Comparator.comparingDouble(VehicleMatchResponse::getMatchScore).reversed())
                .collect(Collectors.toList());
    }

    private double calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
        final int R = 6371; // Bán kính Trái Đất (km)
        double latDistance = Math.toRadians(lat2 - lat1);
        double lonDistance = Math.toRadians(lon2 - lon1);
        double a = Math.sin(latDistance / 2) * Math.sin(latDistance / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(lonDistance / 2) * Math.sin(lonDistance / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }
}

