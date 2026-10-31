package com.autorental.backend.controller;

import com.autorental.backend.dto.request.UpdateProfileRequest;
import com.autorental.backend.dto.response.ApiResponse;
import com.autorental.backend.model.User;
import com.autorental.backend.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final AuthService authService;

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<User>> getCurrentUser() {
        User currentUser = authService.getCurrentUser();
        return ResponseEntity.ok(ApiResponse.success("Lấy Profile thành công", currentUser));
    }

    @PutMapping("/me")
    public ResponseEntity<ApiResponse<User>> updateProfile(@RequestBody UpdateProfileRequest request) {
        User currentUser = authService.getCurrentUser();
        User updated = authService.updateProfile(currentUser.getId(), request);
        return ResponseEntity.ok(ApiResponse.success("Cập nhật Profile thành công", updated));
    }
}

