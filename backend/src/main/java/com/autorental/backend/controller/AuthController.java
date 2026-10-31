package com.autorental.backend.controller;

import com.autorental.backend.dto.request.LoginRequest;
import com.autorental.backend.dto.request.RegisterRequest;
import com.autorental.backend.dto.request.SwitchRoleRequest;
import com.autorental.backend.dto.response.ApiResponse;
import com.autorental.backend.dto.response.JwtResponse;
import com.autorental.backend.model.User;
import com.autorental.backend.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<User>> register(@Valid @RequestBody RegisterRequest request) {
        User user = authService.register(request);
        return ResponseEntity.ok(ApiResponse.success("Đăng ký tài khoản thành công", user));
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<JwtResponse>> login(@Valid @RequestBody LoginRequest request) {
        JwtResponse jwtResponse = authService.login(request);
        return ResponseEntity.ok(ApiResponse.success("Đăng nhập thành công", jwtResponse));
    }

    @PutMapping("/switch-role")
    public ResponseEntity<ApiResponse<User>> switchRole(@Valid @RequestBody SwitchRoleRequest request) {
        User currentUser = authService.getCurrentUser();
        User updatedUser = authService.switchRole(currentUser.getId(), request);
        return ResponseEntity.ok(ApiResponse.success("Chuyển đổi vai trò thành công", updatedUser));
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<User>> getCurrentUser() {
        User currentUser = authService.getCurrentUser();
        return ResponseEntity.ok(ApiResponse.success("Lấy thông tin người dùng thành công", currentUser));
    }
}

