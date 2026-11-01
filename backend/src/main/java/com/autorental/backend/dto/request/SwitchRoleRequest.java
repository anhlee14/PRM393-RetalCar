package com.autorental.backend.dto.request;

import com.autorental.backend.model.Role;
import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class SwitchRoleRequest {
    @NotNull(message = "Vai trò đích không được để trống")
    @JsonAlias({"targetRole", "target_role"})
    private Role targetRole;
}

