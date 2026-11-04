package com.autorental.backend.controller;

import com.autorental.backend.dto.request.GpsPingRequest;
import com.autorental.backend.dto.response.ApiResponse;
import com.autorental.backend.dto.response.GpsSnapshotResponse;
import com.autorental.backend.dto.response.GpsStatusResponse;
import com.autorental.backend.model.GpsLog;
import com.autorental.backend.model.User;
import com.autorental.backend.service.AuthService;
import com.autorental.backend.service.GpsService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/gps")
@RequiredArgsConstructor
public class GpsController {

    private final GpsService gpsService;
    private final AuthService authService;

    // Feature 2: Người thuê gửi toạ độ GPS (Bắt buộc tối đa 1 tiếng / lần khi đơn đang ONGOING)
    @PostMapping("/ping")
    public ResponseEntity<ApiResponse<GpsLog>> pingGps(@Valid @RequestBody GpsPingRequest request) {
        User currentUser = authService.getCurrentUser();
        GpsLog log = gpsService.recordPing(request, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Cập nhật toạ độ GPS thành công", log));
    }

    // Feature 2: Người thuê xe xem FULL lộ trình di chuyển của mình
    @GetMapping("/renter-route/{bookingId}")
    public ResponseEntity<ApiResponse<List<GpsLog>>> getRenterFullRoute(@PathVariable Long bookingId) {
        User renter = authService.getCurrentUser();
        List<GpsLog> route = gpsService.getRenterFullRoute(bookingId, renter.getId());
        return ResponseEntity.ok(ApiResponse.success("Lấy toàn bộ lộ trình xe thành công", route));
    }

    // Feature 2: Chủ xe chỉ xem Snapshot toạ độ tức thời + Giới hạn 20 lần / ngày (-1 lượt mỗi khi gọi)
    @GetMapping("/owner-snapshot/{bookingId}")
    public ResponseEntity<ApiResponse<GpsSnapshotResponse>> getOwnerSnapshot(@PathVariable Long bookingId) {
        User owner = authService.getCurrentUser();
        GpsSnapshotResponse snapshot = gpsService.getOwnerSnapshot(bookingId, owner);
        return ResponseEntity.ok(ApiResponse.success("Lấy vị trí hiện tại của xe thành công", snapshot));
    }

    // Feature 2: Kiểm tra tình trạng bật GPS (có quá 60 phút không) & số lượt Quota còn lại (không trừ lượt)
    @GetMapping("/status/{bookingId}")
    public ResponseEntity<ApiResponse<GpsStatusResponse>> checkGpsStatus(@PathVariable Long bookingId) {
        GpsStatusResponse status = gpsService.checkGpsStatus(bookingId);
        return ResponseEntity.ok(ApiResponse.success("Kiểm tra trạng thái GPS thành công", status));
    }
}
