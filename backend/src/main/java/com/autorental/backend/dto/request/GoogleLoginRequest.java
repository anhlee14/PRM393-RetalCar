package com.autorental.backend.dto.request;

import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class GoogleLoginRequest {

    @NotBlank(message = "Google ID Token không được để trống")
    @JsonAlias({"idToken", "id_token"})
    private String idToken;
}

