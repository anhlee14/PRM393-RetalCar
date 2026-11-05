package com.autorental.backend.controller;

import com.autorental.backend.dto.request.VehicleRequest;
import com.autorental.backend.dto.response.ApiResponse;
import com.autorental.backend.exception.BadRequestException;
import com.autorental.backend.model.Role;
import com.autorental.backend.model.User;
import com.autorental.backend.model.Vehicle;
import com.autorental.backend.model.VehicleStatus;
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

    private void requireAdminRole() {
        User currentUser = authService.getCurrentUser();
        if (currentUser.getRole() != Role.ROLE_ADMIN) {
            throw new BadRequestException("Chỉ Quản trị viên (Admin) mới có quyền duyệt hoặc từ chối xe đăng ký!");
        }
    }

    @PostMapping
    public ResponseEntity<ApiResponse<Vehicle>> createVehicle(@Valid @RequestBody VehicleRequest request) {
        User owner = authService.getCurrentUser();
        Vehicle vehicle = vehicleService.createVehicle(owner, request);
        return ResponseEntity.ok(ApiResponse.success("Đăng tải xe thành công! Xe đang chờ Admin phê duyệt.", vehicle));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<Vehicle>> updateVehicle(
            @PathVariable Long id,
            @Valid @RequestBody VehicleRequest request) {
        User owner = authService.getCurrentUser();
        Vehicle vehicle = vehicleService.updateVehicle(id, owner, request);
        return ResponseEntity.ok(ApiResponse.success("Cập nhật thông tin xe thành công", vehicle));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteVehicle(@PathVariable Long id) {
        User owner = authService.getCurrentUser();
        vehicleService.deleteVehicle(id, owner);
        return ResponseEntity.ok(ApiResponse.success("Xóa xe thành công", null));
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

    @GetMapping("/pending")
    public ResponseEntity<ApiResponse<List<Vehicle>>> getPendingVehicles() {
        requireAdminRole();
        List<Vehicle> list = vehicleService.getPendingVehicles();
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách xe chờ duyệt thành công", list));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Vehicle>> getVehicleById(@PathVariable Long id) {
        Vehicle vehicle = vehicleService.getVehicleById(id);
        return ResponseEntity.ok(ApiResponse.success("Lấy thông tin chi tiết xe thành công", vehicle));
    }

    // Logic: Chỉ Admin mới có quyền duyệt xe cho thuê
    @RequestMapping(value = "/{id}/approve", method = {RequestMethod.PATCH, RequestMethod.PUT})
    public ResponseEntity<ApiResponse<Vehicle>> approveVehicle(@PathVariable Long id) {
        requireAdminRole();
        Vehicle vehicle = vehicleService.updateVehicleStatus(id, VehicleStatus.AVAILABLE);
        return ResponseEntity.ok(ApiResponse.success("Duyệt xe thành công, xe đã sẵn sàng cho thuê", vehicle));
    }

    // Logic: Chỉ Admin mới có quyền từ chối duyệt xe
    @RequestMapping(value = "/{id}/reject", method = {RequestMethod.PATCH, RequestMethod.PUT})
    public ResponseEntity<ApiResponse<Vehicle>> rejectVehicle(@PathVariable Long id) {
        requireAdminRole();
        Vehicle vehicle = vehicleService.updateVehicleStatus(id, VehicleStatus.REJECTED);
        return ResponseEntity.ok(ApiResponse.success("Đã từ chối duyệt xe", vehicle));
    }
}
