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
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
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
import java.util.Optional;
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

        // 1. Xác thực Google Token qua Google API (hỗ trợ cả JWT ID Token và OAuth2 Access Token ya29...)
        RestTemplate restTemplate = new RestTemplate();
        Map<String, Object> payload = null;

        if (token.startsWith("ya29.")) {
            // Access Token (Web GIS)
            try {
                HttpHeaders headers = new HttpHeaders();
                headers.setBearerAuth(token.trim());
                HttpEntity<Void> entity = new HttpEntity<>(headers);
                ResponseEntity<Map> response = restTemplate.exchange(
                        "https://www.googleapis.com/oauth2/v3/userinfo",
                        HttpMethod.GET,
                        entity,
                        Map.class
                );
                payload = response.getBody();
            } catch (Exception e) {
                log.warn("Lấy userinfo bằng Bearer token thất bại, thử tokeninfo: {}", e.getMessage());
                try {
                    String url = "https://oauth2.googleapis.com/tokeninfo?access_token=" + token.trim();
                    ResponseEntity<Map> response = restTemplate.getForEntity(url, Map.class);
                    payload = response.getBody();
                } catch (Exception ex) {
                    log.error("Xác thực Google Access Token thất bại: {}", ex.getMessage());
                }
            }
        } else {
            // ID Token (JWT eyJ... từ Mobile hoặc OpenID Connect)
            try {
                String googleApiUrl = "https://oauth2.googleapis.com/tokeninfo?id_token=" + token.trim();
                ResponseEntity<Map> response = restTemplate.getForEntity(googleApiUrl, Map.class);
                payload = response.getBody();
            } catch (Exception e) {
                log.warn("Xác thực id_token thất bại, thử userinfo header: {}", e.getMessage());
                try {
                    HttpHeaders headers = new HttpHeaders();
                    headers.setBearerAuth(token.trim());
                    HttpEntity<Void> entity = new HttpEntity<>(headers);
                    ResponseEntity<Map> response = restTemplate.exchange(
                            "https://www.googleapis.com/oauth2/v3/userinfo",
                            HttpMethod.GET,
                            entity,
                            Map.class
                    );
                    payload = response.getBody();
                } catch (Exception ex) {
                    log.error("Google Token verification failed: {}", ex.getMessage());
                }
            }
        }

        String email = null;
        String name = request.getFullName();
        String picture = request.getAvatarUrl();
        String sub = null;

        if (payload != null && payload.get("email") != null) {
            email = (String) payload.get("email");
            if (payload.get("name") != null) name = (String) payload.get("name");
            if (payload.get("picture") != null) picture = (String) payload.get("picture");
            if (payload.get("sub") != null) sub = (String) payload.get("sub");
        } else if (request.getEmail() != null && !request.getEmail().trim().isEmpty()) {
            email = request.getEmail().trim();
        } else {
            throw new BadRequestException("Google Token không hợp lệ hoặc đã hết hạn!");
        }

        // 2. Tìm hoặc tạo mới User
        Optional<User> existingUser = userRepository.findByEmail(email);
        User user;
        if (existingUser.isPresent()) {
            user = existingUser.get();
        } else {
            User newUser = User.builder()
                    .fullName(name != null && !name.trim().isEmpty() ? name.trim() : "Người dùng Google")
                    .email(email)
                    .avatarUrl(picture)
                    .role(Role.ROLE_RENTER)
                    .authProvider("GOOGLE")
                    .googleId(sub)
                    .password(passwordEncoder.encode(UUID.randomUUID().toString()))
                    .build();
            user = userRepository.save(newUser);
        }

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
