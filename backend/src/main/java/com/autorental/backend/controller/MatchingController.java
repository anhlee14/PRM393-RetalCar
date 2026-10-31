package com.autorental.backend.controller;

import com.autorental.backend.dto.request.MatchingFilterRequest;
import com.autorental.backend.dto.response.ApiResponse;
import com.autorental.backend.dto.response.VehicleMatchResponse;
import com.autorental.backend.service.MatchingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/vehicles/match")
@RequiredArgsConstructor
public class MatchingController {

    private final MatchingService matchingService;

    // Feature 4: Thuật toán Matching tìm xe theo tỉ lệ % khớp
    @PostMapping
    public ResponseEntity<ApiResponse<List<VehicleMatchResponse>>> matchVehicles(
            @RequestBody MatchingFilterRequest filter) {

        List<VehicleMatchResponse> matches = matchingService.matchVehicles(filter);
        return ResponseEntity.ok(ApiResponse.success("Tìm kiếm và so khớp xe thành công", matches));
    }
}

