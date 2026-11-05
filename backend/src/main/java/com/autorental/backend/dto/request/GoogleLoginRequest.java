package com.autorental.backend.dto.request;

import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class GoogleLoginRequest {

    @NotBlank(message = "Google Token không được để trống")
    @JsonAlias({"idToken", "id_token"})
    private String idToken;

    @JsonAlias({"email"})
    private String email;

    @JsonAlias({"fullName", "full_name", "name"})
    private String fullName;

    @JsonAlias({"avatarUrl", "avatar_url", "picture"})
    private String avatarUrl;
}
