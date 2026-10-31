package com.autorental.backend.controller;

import com.autorental.backend.dto.request.InspectionRequest;
import com.autorental.backend.dto.response.ApiResponse;
import com.autorental.backend.dto.response.InspectionComparisonResponse;
import com.autorental.backend.model.Inspection;
import com.autorental.backend.model.User;
import com.autorental.backend.service.AuthService;
import com.autorental.backend.service.InspectionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/inspections")
@RequiredArgsConstructor
public class InspectionController {

    private final InspectionService inspectionService;
    private final AuthService authService;

    // Feature 3: Gửi ảnh hiện trạng xe (Check-in hoặc Check-out)
    @PostMapping
    public ResponseEntity<ApiResponse<Inspection>> saveInspection(@Valid @RequestBody InspectionRequest request) {
        Inspection inspection = inspectionService.saveInspection(request);
        return ResponseEntity.ok(ApiResponse.success("Lưu biên bản thẩm định xe thành công", inspection));
    }

    // Feature 3: Xác nhận biên bản (Chủ xe hoặc Khách thuê)
    @PutMapping("/{id}/confirm")
    public ResponseEntity<ApiResponse<Inspection>> confirmInspection(@PathVariable Long id) {
        User user = authService.getCurrentUser();
        Inspection inspection = inspectionService.confirmInspection(id, user);
        return ResponseEntity.ok(ApiResponse.success("Xác nhận biên bản thẩm định thành công", inspection));
    }

    // Feature 3: Màn hình so sánh đối chiếu ảnh Trước & Sau (Before - After)
    @GetMapping("/{bookingId}/comparison")
    public ResponseEntity<ApiResponse<InspectionComparisonResponse>> getComparison(@PathVariable Long bookingId) {
        InspectionComparisonResponse response = inspectionService.getComparison(bookingId);
        return ResponseEntity.ok(ApiResponse.success("Lấy dữ liệu đối chiếu trước - sau thành công", response));
    }
}

