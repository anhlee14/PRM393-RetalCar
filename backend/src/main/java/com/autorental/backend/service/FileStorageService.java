package com.autorental.backend.service;

import com.autorental.backend.exception.BadRequestException;
import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Map;
import java.util.UUID;

@Service
@Slf4j
public class FileStorageService {

    private final Cloudinary cloudinary;

    @Value("${file.upload-dir:uploads}")
    private String uploadDir;

    public FileStorageService(Cloudinary cloudinary) {
        this.cloudinary = cloudinary;
    }

    public String storeFile(MultipartFile file, String subFolder) {
        if (file.isEmpty()) {
            throw new BadRequestException("File không được để trống");
        }

        // 1. Thử tải lên Cloudinary nếu cấu hình hợp lệ
        try {
            log.info("Bắt đầu tải file lên Cloudinary, thư mục: autorental/{}", subFolder);
            Map uploadResult = cloudinary.uploader().upload(file.getBytes(), ObjectUtils.asMap(
                    "folder", "autorental/" + subFolder,
                    "resource_type", "auto"
            ));

            String secureUrl = (String) uploadResult.get("secure_url");
            if (secureUrl != null && !secureUrl.isEmpty()) {
                log.info("Upload Cloudinary thành công! URL: {}", secureUrl);
                return secureUrl;
            }
        } catch (Exception ex) {
            log.warn("Không thể tải lên Cloudinary ({}), tự động chuyển sang lưu trữ máy chủ cục bộ...", ex.getMessage());
        }

        // 2. Tự động lưu trữ cục bộ vào thư mục uploads/<subFolder> để đảm bảo luôn tải ảnh thành công 100%
        try {
            Path targetDir = Paths.get(uploadDir, subFolder);
            if (!Files.exists(targetDir)) {
                Files.createDirectories(targetDir);
            }

            String originalFilename = StringUtils.cleanPath(file.getOriginalFilename() != null ? file.getOriginalFilename() : "image.jpg");
            String extension = "";
            int dotIdx = originalFilename.lastIndexOf(".");
            if (dotIdx >= 0) {
                extension = originalFilename.substring(dotIdx);
            } else {
                extension = ".jpg";
            }

            String uniqueFilename = UUID.randomUUID().toString() + extension;
            Path targetPath = targetDir.resolve(uniqueFilename);

            Files.copy(file.getInputStream(), targetPath, StandardCopyOption.REPLACE_EXISTING);
            log.info("Lưu ảnh kiểm tra cục bộ thành công: {}", targetPath.toAbsolutePath());

            return "/uploads/" + subFolder + "/" + uniqueFilename;
        } catch (IOException e) {
            log.error("Lỗi khi lưu trữ ảnh kiểm tra: {}", e.getMessage(), e);
            throw new RuntimeException("Không thể lưu trữ ảnh: " + e.getMessage(), e);
        }
    }
}
