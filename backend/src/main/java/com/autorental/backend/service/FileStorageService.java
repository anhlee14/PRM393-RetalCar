package com.autorental.backend.service;

import com.autorental.backend.exception.BadRequestException;
import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Map;

@Service
@Slf4j
public class FileStorageService {

    private final Cloudinary cloudinary;

    public FileStorageService(Cloudinary cloudinary) {
        this.cloudinary = cloudinary;
    }

    public String storeFile(MultipartFile file, String subFolder) {
        if (file.isEmpty()) {
            throw new BadRequestException("File không được để trống");
        }

        try {
            log.info("Bắt đầu tải file lên Cloudinary, thư mục: autorental/{}", subFolder);
            Map uploadResult = cloudinary.uploader().upload(file.getBytes(), ObjectUtils.asMap(
                    "folder", "autorental/" + subFolder,
                    "resource_type", "image"
            ));

            String secureUrl = (String) uploadResult.get("secure_url");
            log.info("Upload Cloudinary thành công! URL: {}", secureUrl);
            return secureUrl;
        } catch (IOException ex) {
            log.error("Lỗi khi tải file lên Cloudinary: {}", ex.getMessage());
            throw new RuntimeException("Không thể tải file lên Cloudinary: " + ex.getMessage(), ex);
        }
    }
}
