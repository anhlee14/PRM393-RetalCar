package com.autorental.backend.service;

import com.autorental.backend.exception.BadRequestException;
import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

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
    private final String cloudName;
    private final String apiKey;
    private final String apiSecret;
    private final Path fileStorageLocation;

    public FileStorageService(
            Cloudinary cloudinary,
            @Value("${cloudinary.cloud-name:}") String cloudName,
            @Value("${cloudinary.api-key:}") String apiKey,
            @Value("${cloudinary.api-secret:}") String apiSecret,
            @Value("${file.upload-dir:uploads}") String uploadDir) {
        this.cloudinary = cloudinary;
        this.cloudName = cloudName != null ? cloudName.trim() : "";
        this.apiKey = apiKey != null ? apiKey.trim() : "";
        this.apiSecret = apiSecret != null ? apiSecret.trim() : "";
        this.fileStorageLocation = Paths.get(uploadDir).toAbsolutePath().normalize();
        try {
            Files.createDirectories(this.fileStorageLocation);
            Files.createDirectories(this.fileStorageLocation.resolve("vehicles"));
            Files.createDirectories(this.fileStorageLocation.resolve("inspections"));
            Files.createDirectories(this.fileStorageLocation.resolve("avatars"));
        } catch (IOException ex) {
            log.warn("Không thể khởi tạo sẵn thư mục uploads cục bộ: {}", ex.getMessage());
        }
    }

    public String storeFile(MultipartFile file, String subFolder) {
        if (file == null || file.isEmpty()) {
            throw new BadRequestException("File không được để trống");
        }

        String safeFolder = (subFolder == null || subFolder.trim().isEmpty())
                ? "vehicles"
                : subFolder.trim().replaceAll("[^a-zA-Z0-9_-]", "");

        // 1. Thử tải lên Cloudinary trước
        try {
            log.info("Bắt đầu tải file lên Cloudinary, thư mục: autorental/{}", safeFolder);
            Map<?, ?> uploadResult = cloudinary.uploader().upload(file.getBytes(), ObjectUtils.asMap(
                    "folder", "autorental/" + safeFolder,
                    "resource_type", "image"
            ));
            String secureUrl = (String) uploadResult.get("secure_url");
            if (secureUrl != null && !secureUrl.isEmpty()) {
                log.info("Upload Cloudinary thành công! URL: {}", secureUrl);
                return secureUrl;
            }
        } catch (Exception ex) {
            log.warn("Upload Cloudinary với cloud_name='{}' thất bại: {}", cloudName, ex.getMessage());
            // Thử lại với tiền tố 'd' nếu cloud_name bị thiếu ký tự 'd' ở đầu (VD: rr3lj0rn -> drr3lj0rn)
            if (!cloudName.isEmpty() && !cloudName.startsWith("d")) {
                try {
                    String altCloudName = "d" + cloudName;
                    Cloudinary altCloudinary = new Cloudinary(ObjectUtils.asMap(
                            "cloud_name", altCloudName,
                            "api_key", apiKey,
                            "api_secret", apiSecret,
                            "secure", true
                    ));
                    Map<?, ?> altResult = altCloudinary.uploader().upload(file.getBytes(), ObjectUtils.asMap(
                            "folder", "autorental/" + safeFolder,
                            "resource_type", "image"
                    ));
                    String secureUrl = (String) altResult.get("secure_url");
                    if (secureUrl != null && !secureUrl.isEmpty()) {
                        log.info("Upload Cloudinary (cloud_name='{}') thành công! URL: {}", altCloudName, secureUrl);
                        return secureUrl;
                    }
                } catch (Exception altEx) {
                    log.warn("Upload Cloudinary dự phòng thất bại, chuyển sang lưu file cục bộ: {}", altEx.getMessage());
                }
            }
        }

        // 2. Fallback: Lưu file cục bộ vào thư mục uploads/ để không bao giờ bị lỗi đăng ký xe
        return storeFileLocally(file, safeFolder);
    }

    private String storeFileLocally(MultipartFile file, String safeFolder) {
        String originalFileName = file.getOriginalFilename();
        String fileExtension = ".jpg";
        if (originalFileName != null && originalFileName.contains(".")) {
            fileExtension = originalFileName.substring(originalFileName.lastIndexOf("."));
        }

        String fileName = UUID.randomUUID().toString() + fileExtension;
        try {
            Path targetDir = this.fileStorageLocation.resolve(safeFolder);
            Files.createDirectories(targetDir);
            Path targetLocation = targetDir.resolve(fileName);
            Files.copy(file.getInputStream(), targetLocation, StandardCopyOption.REPLACE_EXISTING);

            String localUrl = ServletUriComponentsBuilder.fromCurrentContextPath()
                    .path("/uploads/")
                    .path(safeFolder + "/")
                    .path(fileName)
                    .toUriString();
            log.info("Đã lưu file cục bộ thành công (Fallback): {}", localUrl);
            return localUrl;
        } catch (IOException ex) {
            log.error("Lỗi khi lưu file cục bộ: {}", ex.getMessage());
            throw new BadRequestException("Không thể lưu file tải lên: " + ex.getMessage());
        }
    }
}
