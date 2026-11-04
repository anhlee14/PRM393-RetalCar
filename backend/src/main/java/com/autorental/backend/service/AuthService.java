package com.autorental.backend.service;

import com.autorental.backend.dto.request.GoogleLoginRequest;
import com.autorental.backend.dto.request.LoginRequest;
import com.autorental.backend.dto.request.RefreshTokenRequest;
import com.autorental.backend.dto.request.RegisterRequest;
import com.autorental.backend.dto.request.SwitchRoleRequest;
import com.autorental.backend.dto.request.UpdateProfileRequest;
import com.autorental.backend.dto.response.JwtResponse;
import com.autorental.backend.dto.response.TokenRefreshResponse;
import com.autorental.backend.exception.BadRequestException;
import com.autorental.backend.exception.ResourceNotFoundException;
import com.autorental.backend.model.RefreshToken;
import com.autorental.backend.model.Role;
import com.autorental.backend.model.User;
import com.autorental.backend.repository.UserRepository;
import com.autorental.backend.security.JwtUtils;
import com.autorental.backend.security.UserDetailsImpl;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.util.Map;
import java.util.UUID;

@Service
@Slf4j
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtUtils jwtUtils;
    private final RefreshTokenService refreshTokenService;

    @Transactional
    public User register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new BadRequestException("Email đã được sử dụng");
        }
        if (userRepository.existsByPhone(request.getPhone())) {
            throw new BadRequestException("Số điện thoại đã được sử dụng");
        }

        User user = User.builder()
                .fullName(request.getFullName())
                .email(request.getEmail())
                .phone(request.getPhone())
                .password(passwordEncoder.encode(request.getPassword()))
                .role(request.getRole() != null ? request.getRole() : Role.ROLE_RENTER)
                .cccdNumber(request.getCccdNumber())
                .driverLicense(request.getDriverLicense())
                .build();

        return userRepository.save(user);
    }

    @Transactional
    public JwtResponse login(LoginRequest request) {
        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getUsername(), request.getPassword()));

        SecurityContextHolder.getContext().setAuthentication(authentication);
        String jwt = jwtUtils.generateJwtToken(authentication);

        UserDetailsImpl userDetails = (UserDetailsImpl) authentication.getPrincipal();
        User user = userRepository.findById(userDetails.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy người dùng"));

        // Tạo Refresh Token
        RefreshToken refreshToken = refreshTokenService.createRefreshToken(user);

        return JwtResponse.builder()
                .token(jwt)
                .refreshToken(refreshToken.getToken())
                .id(user.getId())
                .fullName(user.getFullName())
                .email(user.getEmail())
                .phone(user.getPhone())
                .role(user.getRole().name())
                .avatarUrl(user.getAvatarUrl())
                .build();
    }

    @Transactional
    public TokenRefreshResponse refreshToken(RefreshTokenRequest request) {
        String requestRefreshToken = request.getRefreshToken();

        return refreshTokenService.findByToken(requestRefreshToken)
                .map(refreshTokenService::verifyExpiration)
                .map(RefreshToken::getUser)
                .map(user -> {
                    String newAccessToken = jwtUtils.generateTokenFromUser(user);
                    return TokenRefreshResponse.builder()
                            .accessToken(newAccessToken)
                            .refreshToken(requestRefreshToken)
                            .build();
                })
                .orElseThrow(() -> new BadRequestException("Refresh token không tồn tại trong hệ thống!"));
    }

    @Transactional
    public User updateProfile(Long userId, UpdateProfileRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy người dùng"));

        if (request.getPhone() != null && !request.getPhone().equals(user.getPhone())) {
            if (userRepository.existsByPhone(request.getPhone())) {
                throw new BadRequestException("Số điện thoại mới đã được sử dụng bởi tài khoản khác!");
            }
            user.setPhone(request.getPhone());
        }

        if (request.getFullName() != null && !request.getFullName().trim().isEmpty()) {
            user.setFullName(request.getFullName().trim());
        }
        if (request.getAvatarUrl() != null) {
            user.setAvatarUrl(request.getAvatarUrl());
        }
        if (request.getCccdNumber() != null) {
            user.setCccdNumber(request.getCccdNumber());
        }
        if (request.getDriverLicense() != null) {
            user.setDriverLicense(request.getDriverLicense());
        }

        return userRepository.save(user);
    }

    @Transactional
    public User switchRole(Long userId, SwitchRoleRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy người dùng"));

        user.setRole(request.getTargetRole());
        return userRepository.save(user);
    }

    public User getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !(authentication.getPrincipal() instanceof UserDetailsImpl)) {
            throw new BadRequestException("Người dùng chưa đăng nhập");
        }
        UserDetailsImpl userDetails = (UserDetailsImpl) authentication.getPrincipal();
        return userRepository.findById(userDetails.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy người dùng hiện tại"));
    }

    @Transactional
    public JwtResponse loginWithGoogle(GoogleLoginRequest request) {
        String token = request.getIdToken();
        if (token == null || token.trim().isEmpty()) {
            throw new BadRequestException("Google Token không được để trống");
        }

        // 1. Xác thực Google Token qua Google Tokeninfo hoặc Userinfo API (hỗ trợ cả id_token và access_token)
        token = token.trim();
        RestTemplate restTemplate = new RestTemplate();
        Map<String, Object> payload = null;

        try {
            // Thử xác thực theo ID Token trước
            String googleApiUrl = "https://oauth2.googleapis.com/tokeninfo?id_token=" + token;
            ResponseEntity<Map> response = restTemplate.getForEntity(googleApiUrl, Map.class);
            payload = response.getBody();
        } catch (Exception ignored) {
            // Nếu không phải ID Token (trên Web thường trả về Access Token), gọi Google Userinfo API
            try {
                org.springframework.http.HttpHeaders headers = new org.springframework.http.HttpHeaders();
                headers.setBearerAuth(token);
                org.springframework.http.HttpEntity<Void> entity = new org.springframework.http.HttpEntity<>(headers);
                ResponseEntity<Map> userinfoResponse = restTemplate.exchange(
                        "https://www.googleapis.com/oauth2/v3/userinfo",
                        org.springframework.http.HttpMethod.GET,
                        entity,
                        Map.class
                );
                payload = userinfoResponse.getBody();
            } catch (Exception ex2) {
                log.error("Google Token verification failed: {}", ex2.getMessage());
                throw new BadRequestException("Google Token không hợp lệ hoặc đã hết hạn!");
            }
        }

        if (payload == null || payload.get("email") == null) {
            throw new BadRequestException("Không thể lấy thông tin email từ Google Token");
        }

        String email = (String) payload.get("email");
        String name = (String) payload.get("name");
        String picture = (String) payload.get("picture");
        String sub = (String) payload.get("sub");

        // 2. Tìm hoặc tạo mới User
        User user = userRepository.findByEmail(email).orElseGet(() -> {
            User newUser = User.builder()
                    .fullName(name != null && !name.trim().isEmpty() ? name : "Người dùng Google")
                    .email(email)
                    .avatarUrl(picture)
                    .role(Role.ROLE_RENTER)
                    .authProvider("GOOGLE")
                    .googleId(sub)
                    .password(passwordEncoder.encode(UUID.randomUUID().toString()))
                    .build();
            return userRepository.save(newUser);
        });

        // Cập nhật thông tin avatar hoặc googleId nếu có
        boolean updated = false;
        if (user.getAvatarUrl() == null && picture != null) {
            user.setAvatarUrl(picture);
            updated = true;
        }
        if (user.getGoogleId() == null && sub != null) {
            user.setGoogleId(sub);
            updated = true;
        }
        if (updated) {
            userRepository.save(user);
        }

        // 3. Tạo JWT Token & Refresh Token của AutoRental
        String jwt = jwtUtils.generateTokenFromUser(user);
        RefreshToken refreshToken = refreshTokenService.createRefreshToken(user);

        return JwtResponse.builder()
                .token(jwt)
                .refreshToken(refreshToken.getToken())
                .id(user.getId())
                .fullName(user.getFullName())
                .email(user.getEmail())
                .phone(user.getPhone())
                .role(user.getRole().name())
                .avatarUrl(user.getAvatarUrl())
                .build();
    }
}
