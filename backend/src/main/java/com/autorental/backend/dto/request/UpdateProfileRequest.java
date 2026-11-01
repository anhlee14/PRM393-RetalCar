package com.autorental.backend.dto.request;

import com.fasterxml.jackson.annotation.JsonAlias;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateProfileRequest {

    @JsonAlias({"fullName", "full_name"})
    private String fullName;
    private String phone;
    @JsonAlias({"avatarUrl", "avatar_url"})
    private String avatarUrl;
    @JsonAlias({"cccdNumber", "cccd_number"})
    private String cccdNumber;
    @JsonAlias({"driverLicense", "driver_license"})
    private String driverLicense;
}

