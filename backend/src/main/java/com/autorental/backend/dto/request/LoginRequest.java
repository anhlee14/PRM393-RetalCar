package com.autorental.backend.dto.request;

import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class LoginRequest {
    @NotBlank(message = "Email hoặc số điện thoại không được để trống")
    @JsonAlias({"username", "email", "phone"})
    private String username;

    @NotBlank(message = "Mật khẩu không được để trống")
    private String password;
}

