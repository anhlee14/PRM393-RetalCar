package com.autorental.backend.config;

import com.autorental.backend.model.*;
import com.autorental.backend.repository.BookingRepository;
import com.autorental.backend.repository.GpsLogRepository;
import com.autorental.backend.repository.UserRepository;
import com.autorental.backend.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Component
@Slf4j
@RequiredArgsConstructor
public class DataSeeder implements CommandLineRunner {

        private final UserRepository userRepository;
        private final VehicleRepository vehicleRepository;
        private final BookingRepository bookingRepository;
        private final GpsLogRepository gpsLogRepository;
        private final PasswordEncoder passwordEncoder;
        private final JdbcTemplate jdbcTemplate;

        @Override
        public void run(String... args) throws Exception {
                migrateDatabaseColumns();
                ensureDefaultAccountsExist();

                if (vehicleRepository.count() == 0) {
                        log.info("Bắt đầu khởi tạo dữ liệu xe mẫu (Data Seeding)...");

                        User owner1 = userRepository.findByEmail("owner@gmail.com").orElseThrow();

                        // Tạo Xe mẫu (có toạ độ quanh Hà Nội / ĐH FPT Hòa Lạc)
                        Vehicle v1 = Vehicle.builder()
                                        .owner(owner1)
                                        .name("VinFast VF8 Plus")
                                        .brand("VinFast")
                                        .modelYear(2023)
                                        .licensePlate("30K-888.88")
                                        .vehicleType(VehicleType.SUV)
                                        .transmission(TransmissionType.AUTO)
                                        .fuelType(FuelType.ELECTRIC)
                                        .basePricePerDay(BigDecimal.valueOf(1200000))
                                        // Hỗ trợ thuê kèm tài xế
                                        .hasDriverOption(true)
                                        .driverFeePerDay(BigDecimal.valueOf(450000))
                                        .seats(5)
                                        .description("Xe điện hiện đại, nội thất da cao cấp, hỗ trợ tự lái hoặc có tài xế phục vụ tận tình.")
                                        .address("Khu Công Nghệ Cao Hòa Lạc, Thạch Thất, Hà Nội")
                                        .currentLat(21.0131)
                                        .currentLng(105.5255)
                                        .averageRating(4.9)
                                        .totalReviews(28)
                                        .status(VehicleStatus.AVAILABLE)
                                        .thumbnailUrl("https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/2022_Vinfast_VF8_front_view.jpg/1280px-2022_Vinfast_VF8_front_view.jpg")
                                        .build();

                        Vehicle v2 = Vehicle.builder()
                                        .owner(owner1)
                                        .name("Toyota Vios G")
                                        .brand("Toyota")
                                        .modelYear(2022)
                                        .licensePlate("29A-666.99")
                                        .vehicleType(VehicleType.SEDAN)
                                        .transmission(TransmissionType.AUTO)
                                        .fuelType(FuelType.PETROL)
                                        .basePricePerDay(BigDecimal.valueOf(650000))
                                        // Chỉ cho thuê tự lái
                                        .hasDriverOption(false)
                                        .driverFeePerDay(BigDecimal.ZERO)
                                        .seats(5)
                                        .description("Xe sedan tiết kiệm nhiên liệu, máy êm, phù hợp gia đình đi du lịch hoặc công tác.")
                                        .address("Cầu Giấy, Hà Nội")
                                        .currentLat(21.0333)
                                        .currentLng(105.7833)
                                        .averageRating(4.8)
                                        .totalReviews(45)
                                        .status(VehicleStatus.AVAILABLE)
                                        .thumbnailUrl("https://upload.wikimedia.org/wikipedia/commons/thumb/0/0e/Toyota_Vios_1.5_G_2019_%282%29.jpg/1280px-Toyota_Vios_1.5_G_2019_%282%29.jpg")
                                        .build();

                        Vehicle v3 = Vehicle.builder()
                                        .owner(owner1)
                                        .name("Mitsubishi Xpander Cross")
                                        .brand("Mitsubishi")
                                        .modelYear(2023)
                                        .licensePlate("30H-999.11")
                                        .vehicleType(VehicleType.MPV)
                                        .transmission(TransmissionType.AUTO)
                                        .fuelType(FuelType.PETROL)
                                        .basePricePerDay(BigDecimal.valueOf(850000))
                                        // Hỗ trợ thuê kèm tài xế
                                        .hasDriverOption(true)
                                        .driverFeePerDay(BigDecimal.valueOf(400000))
                                        .seats(7)
                                        .description("Xe 7 chỗ rộng rãi, gầm cao, máy lạnh cực mát, có sẵn tài xế giàu kinh nghiệm.")
                                        .address("Nam Từ Liêm, Hà Nội")
                                        .currentLat(21.0167)
                                        .currentLng(105.7667)
                                        .averageRating(4.7)
                                        .totalReviews(19)
                                        .status(VehicleStatus.AVAILABLE)
                                        .thumbnailUrl("https://upload.wikimedia.org/wikipedia/commons/thumb/3/38/Mitsubishi_Xpander_Sport_%28depan%29%2C_Palangkaraya.jpg/1280px-Mitsubishi_Xpander_Sport_%28depan%29%2C_Palangkaraya.jpg")
                                        .build();

                        vehicleRepository.saveAll(List.of(v1, v2, v3));
                }

                // 3. Khởi tạo 1 chuyến đi ONGOING mẫu kèm lộ trình GPS thực tế nếu chưa có đơn thuê nào
                if (bookingRepository.count() == 0) {
                        User renter = userRepository.findByEmail("renter@gmail.com").orElse(null);
                        List<Vehicle> vehicles = vehicleRepository.findAll();
                        if (renter != null && !vehicles.isEmpty()) {
                                Vehicle vehicle = vehicles.get(0);
                                Booking ongoingBooking = Booking.builder()
                                                .renter(renter)
                                                .vehicle(vehicle)
                                                .startDate(LocalDateTime.now().minusHours(2))
                                                .endDate(LocalDateTime.now().plusDays(2))
                                                .withDriver(false)
                                                .carRentalPrice(BigDecimal.valueOf(2400000))
                                                .driverServicePrice(BigDecimal.ZERO)
                                                .totalPrice(BigDecimal.valueOf(2400000))
                                                .depositAmount(BigDecimal.valueOf(720000))
                                                .pickupAddress("Cầu Giấy, Hà Nội")
                                                .returnAddress("Hồ Hoàn Kiếm, Hà Nội")
                                                .status(BookingStatus.ONGOING)
                                                .lastRenterGpsPing(LocalDateTime.now().minusMinutes(12))
                                                .build();
                                Booking savedBooking = bookingRepository.save(ongoingBooking);

                                // Tạo 4 điểm lộ trình GPS dọc theo trục Cầu Giấy -> Kim Mã -> Láng Hạ -> Hồ Gươm
                                GpsLog p1 = GpsLog.builder()
                                                .booking(savedBooking)
                                                .latitude(21.0333)
                                                .longitude(105.7833)
                                                .speed(35.0)
                                                .build();
                                GpsLog p2 = GpsLog.builder()
                                                .booking(savedBooking)
                                                .latitude(21.0308)
                                                .longitude(105.8125)
                                                .speed(42.5)
                                                .build();
                                GpsLog p3 = GpsLog.builder()
                                                .booking(savedBooking)
                                                .latitude(21.0245)
                                                .longitude(105.8252)
                                                .speed(38.0)
                                                .build();
                                GpsLog p4 = GpsLog.builder()
                                                .booking(savedBooking)
                                                .latitude(21.0285)
                                                .longitude(105.8542)
                                                .speed(45.0)
                                                .build();
                                gpsLogRepository.saveAll(List.of(p1, p2, p3, p4));
                                log.info("Đã khởi tạo chuyến xe ONGOING mẫu #BK-{} kèm 4 điểm lộ trình GPS!", savedBooking.getId());
                        }
                }
        }

        private void ensureDefaultAccountsExist() {
                // 1. Đảm bảo tài khoản Admin luôn tồn tại với mật khẩu 123456 và quyền ROLE_ADMIN
                User admin = userRepository.findByEmail("admin@gmail.com").orElse(null);
                if (admin == null) {
                        String adminPhone = userRepository.existsByPhone("0999888999") ? null : "0999888999";
                        admin = User.builder()
                                        .fullName("Quản Trị Viên")
                                        .email("admin@gmail.com")
                                        .phone(adminPhone)
                                        .password(passwordEncoder.encode("123456"))
                                        .role(Role.ROLE_ADMIN)
                                        .cccdNumber("001202009999")
                                        .avatarUrl("https://images.unsplash.com/photo-1472099645785-5658abf4ff4e")
                                        .build();
                        userRepository.save(admin);
                        log.info("Đã tạo tài khoản Admin mặc định: admin@gmail.com / 123456");
                } else {
                        admin.setRole(Role.ROLE_ADMIN);
                        admin.setPassword(passwordEncoder.encode("123456"));
                        userRepository.save(admin);
                        log.info("Đã đồng bộ tài khoản Admin: admin@gmail.com / 123456 (ROLE_ADMIN)");
                }

                // 2. Đảm bảo tài khoản Owner mẫu tồn tại
                if (!userRepository.existsByEmail("owner@gmail.com")) {
                        String ownerPhone = userRepository.existsByPhone("0988111222") ? null : "0988111222";
                        User owner1 = User.builder()
                                        .fullName("Nguyễn Văn Nam")
                                        .email("owner@gmail.com")
                                        .phone(ownerPhone)
                                        .password(passwordEncoder.encode("123456"))
                                        .role(Role.ROLE_OWNER)
                                        .cccdNumber("001202001122")
                                        .driverLicense("B2-998877")
                                        .avatarUrl("https://images.unsplash.com/photo-1534528741775-53994a69daeb")
                                        .build();
                        userRepository.save(owner1);
                }

                // 3. Đảm bảo tài khoản Renter mẫu tồn tại
                if (!userRepository.existsByEmail("renter@gmail.com")) {
                        String renterPhone = userRepository.existsByPhone("0977333444") ? null : "0977333444";
                        User renter1 = User.builder()
                                        .fullName("Trần Thị Khanh")
                                        .email("renter@gmail.com")
                                        .phone(renterPhone)
                                        .password(passwordEncoder.encode("123456"))
                                        .role(Role.ROLE_RENTER)
                                        .cccdNumber("001202003344")
                                        .driverLicense("B1-112233")
                                        .avatarUrl("https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d")
                                        .build();
                        userRepository.save(renter1);
                }
        }

        private void migrateDatabaseColumns() {
                String[] alterStatements = {
                        "ALTER TABLE vehicles MODIFY COLUMN status VARCHAR(50) NOT NULL DEFAULT 'PENDING_APPROVAL'",
                        "ALTER TABLE vehicles MODIFY COLUMN vehicle_type VARCHAR(50) NOT NULL",
                        "ALTER TABLE vehicles MODIFY COLUMN transmission VARCHAR(50) NOT NULL",
                        "ALTER TABLE vehicles MODIFY COLUMN fuel_type VARCHAR(50) NOT NULL",
                        "ALTER TABLE vehicles MODIFY COLUMN thumbnail_url TEXT",
                        "ALTER TABLE vehicles MODIFY COLUMN description TEXT",
                        "ALTER TABLE vehicle_images MODIFY COLUMN image_url TEXT NOT NULL",
                        "ALTER TABLE users MODIFY COLUMN role VARCHAR(50) NOT NULL",
                        "ALTER TABLE users MODIFY COLUMN phone VARCHAR(50) NULL",
                        "ALTER TABLE users MODIFY COLUMN avatar_url TEXT"
                };

                for (String sql : alterStatements) {
                        try {
                                jdbcTemplate.execute(sql);
                        } catch (Exception ignored) {
                                // Bỏ qua nếu bảng hoặc cột chưa tồn tại
                        }
                }
                log.info("Đã đồng bộ cấu trúc cột bảng vehicles, vehicle_images và users.");
        }
}
