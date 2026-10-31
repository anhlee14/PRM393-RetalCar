package com.autorental.backend.controller;

import com.autorental.backend.dto.request.VehicleRequest;
import com.autorental.backend.dto.response.ApiResponse;
import com.autorental.backend.model.User;
import com.autorental.backend.model.Vehicle;
import com.autorental.backend.service.AuthService;
import com.autorental.backend.service.VehicleService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/vehicles")
@RequiredArgsConstructor
public class VehicleController {

    private final VehicleService vehicleService;
    private final AuthService authService;

    @PostMapping
    public ResponseEntity<ApiResponse<Vehicle>> createVehicle(@Valid @RequestBody VehicleRequest request) {
        User owner = authService.getCurrentUser();
        Vehicle vehicle = vehicleService.createVehicle(owner, request);
        return ResponseEntity.ok(ApiResponse.success("Đăng tải xe thành công", vehicle));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<Vehicle>>> getAllAvailableVehicles() {
        List<Vehicle> list = vehicleService.getAllAvailableVehicles();
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách xe thành công", list));
    }

    @GetMapping("/owner")
    public ResponseEntity<ApiResponse<List<Vehicle>>> getOwnerVehicles() {
        User owner = authService.getCurrentUser();
        List<Vehicle> list = vehicleService.getOwnerVehicles(owner.getId());
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách xe của chủ xe thành công", list));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Vehicle>> getVehicleById(@PathVariable Long id) {
        Vehicle vehicle = vehicleService.getVehicleById(id);
        return ResponseEntity.ok(ApiResponse.success("Lấy thông tin chi tiết xe thành công", vehicle));
    }
}

