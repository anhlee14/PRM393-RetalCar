package com.autorental.backend.controller;

import com.autorental.backend.dto.response.ApiResponse;
import com.autorental.backend.service.FileStorageService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/files")
@RequiredArgsConstructor
public class FileUploadController {

    private final FileStorageService fileStorageService;

    @PostMapping("/upload")
    public ResponseEntity<ApiResponse<Map<String, String>>> uploadFile(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "folder", defaultValue = "vehicles") String folder) {

        String fileUrl = fileStorageService.storeFile(file, folder);

        Map<String, String> data = new HashMap<>();
        data.put("file_url", fileUrl);

        return ResponseEntity.ok(ApiResponse.success("Tải file lên thành công", data));
    }
}

