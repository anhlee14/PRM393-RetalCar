package com.autorental.backend.config;

import com.autorental.backend.model.*;
import com.autorental.backend.repository.BookingRepository;
import com.autorental.backend.repository.GpsLogRepository;
import com.autorental.backend.repository.UserRepository;
import com.autorental.backend.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
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

        @Override
        public void run(String... args) throws Exception {
                if (userRepository.count() == 0) {
                        log.info("Bắt đầu khởi tạo dữ liệu mẫu (Data Seeding)...");

                        // 1. Tạo Users
                        User owner1 = User.builder()
                                        .fullName("Nguyễn Văn Nam")
                                        .email("owner@gmail.com")
                                        .phone("0988111222")
                                        .password(passwordEncoder.encode("123456"))
                                        .role(Role.ROLE_OWNER)
                                        .cccdNumber("001202001122")
                                        .driverLicense("B2-998877")
                                        .avatarUrl("https://images.unsplash.com/photo-1534528741775-53994a69daeb")
                                        .build();

                        User renter1 = User.builder()
                                        .fullName("Trần Thị Khanh")
                                        .email("renter@gmail.com")
                                        .phone("0977333444")
                                        .password(passwordEncoder.encode("123456"))
                                        .role(Role.ROLE_RENTER)
                                        .cccdNumber("001202003344")
                                        .driverLicense("B1-112233")
                                        .avatarUrl("https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d")
                                        .build();

                        User admin1 = User.builder()
                                        .fullName("Quản Trị Viên")
                                        .email("admin@gmail.com")
                                        .phone("0999888999")
                                        .password(passwordEncoder.encode("123456"))
                                        .role(Role.ROLE_ADMIN)
                                        .cccdNumber("001202009999")
                                        .avatarUrl("https://images.unsplash.com/photo-1472099645785-5658abf4ff4e")
                                        .build();

                        userRepository.saveAll(List.of(owner1, renter1, admin1));

                        // 2. Tạo Xe mẫu (có toạ độ quanh Hà Nội / ĐH FPT Hòa Lạc)
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

                        log.info("Khởi tạo dữ liệu mẫu thành công! Tài khoản test: owner@gmail.com / 123456 và renter@gmail.com / 123456");
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
}
