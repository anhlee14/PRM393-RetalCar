package com.autorental.backend.dto.request;

import com.autorental.backend.model.Role;
import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class RegisterRequest {
    @NotBlank(message = "Họ và tên không được để trống")
    @JsonAlias({"fullName", "full_name"})
    private String fullName;

    @NotBlank(message = "Email không được để trống")
    @Email(message = "Email không đúng định dạng")
    private String email;

    @NotBlank(message = "Số điện thoại không được để trống")
    private String phone;

    @NotBlank(message = "Mật khẩu không được để trống")
    private String password;

    private Role role = Role.ROLE_RENTER;

    @JsonAlias({"cccdNumber", "cccd_number"})
    private String cccdNumber;

    @JsonAlias({"driverLicense", "driver_license"})
    private String driverLicense;
}

