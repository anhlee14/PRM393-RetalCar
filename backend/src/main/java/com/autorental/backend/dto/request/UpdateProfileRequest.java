package com.autorental.backend.dto.request;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateProfileRequest {

    private String fullName;
    private String phone;
    private String avatarUrl;
    private String cccdNumber;
    private String driverLicense;
}

