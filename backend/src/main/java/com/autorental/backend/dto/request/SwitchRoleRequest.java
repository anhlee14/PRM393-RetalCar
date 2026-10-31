package com.autorental.backend.dto.request;

import com.autorental.backend.model.Role;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class SwitchRoleRequest {
    @NotNull(message = "Vai trò đích không được để trống")
    private Role targetRole;
}

