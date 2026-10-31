package com.autorental.backend.service;

import com.autorental.backend.dto.request.BookingRequest;
import com.autorental.backend.exception.BadRequestException;
import com.autorental.backend.exception.ResourceNotFoundException;
import com.autorental.backend.model.*;
import com.autorental.backend.repository.BookingRepository;
import com.autorental.backend.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;

@Service
@RequiredArgsConstructor
public class BookingService {

    private final BookingRepository bookingRepository;
    private final VehicleRepository vehicleRepository;
    private final NotificationService notificationService;

    @Transactional
    public Booking createBooking(User renter, BookingRequest request) {
        if (request.getEndDate().isBefore(request.getStartDate())) {
            throw new BadRequestException("Ngày trả xe phải sau ngày nhận xe");
        }

        Vehicle vehicle = vehicleRepository.findById(request.getVehicleId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy xe"));

        if (vehicle.getStatus() != VehicleStatus.AVAILABLE) {
            throw new BadRequestException("Xe hiện không sẵn sàng cho thuê");
        }

        // Tính số ngày thuê (tối thiểu 1 ngày)
        long days = ChronoUnit.DAYS.between(request.getStartDate(), request.getEndDate());
        if (days <= 0) days = 1;

        BigDecimal carPrice = vehicle.getBasePricePerDay().multiply(BigDecimal.valueOf(days));
        BigDecimal driverPrice = BigDecimal.ZERO;

        // Feature 1: Tính toán tiền khi thuê kèm lái xe
        if (Boolean.TRUE.equals(request.getWithDriver())) {
            if (!Boolean.TRUE.equals(vehicle.getHasDriverOption())) {
                throw new BadRequestException("Xe này không hỗ trợ tùy chọn thuê kèm tài xế");
            }
            BigDecimal driverFee = vehicle.getDriverFeePerDay() != null ? vehicle.getDriverFeePerDay() : BigDecimal.ZERO;
            driverPrice = driverFee.multiply(BigDecimal.valueOf(days));
        }

        BigDecimal totalPrice = carPrice.add(driverPrice);
        BigDecimal depositAmount = totalPrice.multiply(BigDecimal.valueOf(0.30)); // Đặt cọc 30%

        Booking booking = Booking.builder()
                .renter(renter)
                .vehicle(vehicle)
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .withDriver(request.getWithDriver())
                .carRentalPrice(carPrice)
                .driverServicePrice(driverPrice)
                .totalPrice(totalPrice)
                .depositAmount(depositAmount)
                .pickupAddress(request.getPickupAddress())
                .returnAddress(request.getReturnAddress())
                .status(BookingStatus.PENDING)
                .build();

        Booking savedBooking = bookingRepository.save(booking);

        // Gửi thông báo cho Chủ xe
        notificationService.createNotification(
                vehicle.getOwner(),
                "Yêu cầu đặt xe mới",
                renter.getFullName() + " vừa đặt xe " + vehicle.getName() + " (" + (request.getWithDriver() ? "Có tài xế" : "Tự lái") + ")",
                NotificationType.BOOKING_STATUS,
                savedBooking.getId()
        );

        return savedBooking;
    }

    @Transactional
    public Booking confirmBooking(Long bookingId, User owner) {
        Booking booking = getBookingById(bookingId);
        if (!booking.getVehicle().getOwner().getId().equals(owner.getId())) {
            throw new BadRequestException("Bạn không phải chủ sở hữu của chiếc xe này");
        }

        booking.setStatus(BookingStatus.CONFIRMED);
        booking.getVehicle().setStatus(VehicleStatus.RENTED);
        vehicleRepository.save(booking.getVehicle());
        Booking saved = bookingRepository.save(booking);

        notificationService.createNotification(
                booking.getRenter(),
                "Đơn thuê xe được duyệt",
                "Chủ xe đã đồng ý duyệt đơn thuê xe " + booking.getVehicle().getName() + " của bạn.",
                NotificationType.BOOKING_STATUS,
                saved.getId()
        );

        return saved;
    }

    @Transactional
    public Booking startTrip(Long bookingId) {
        Booking booking = getBookingById(bookingId);
        booking.setStatus(BookingStatus.ONGOING);
        booking.setLastRenterGpsPing(LocalDateTime.now());
        return bookingRepository.save(booking);
    }

    @Transactional
    public Booking completeBooking(Long bookingId) {
        Booking booking = getBookingById(bookingId);
        booking.setStatus(BookingStatus.COMPLETED);
        booking.getVehicle().setStatus(VehicleStatus.AVAILABLE);
        vehicleRepository.save(booking.getVehicle());
        return bookingRepository.save(booking);
    }

    public List<Booking> getRenterBookings(Long renterId) {
        return bookingRepository.findByRenterId(renterId);
    }

    public List<Booking> getOwnerBookings(Long ownerId) {
        return bookingRepository.findByVehicleOwnerId(ownerId);
    }

    public Booking getBookingById(Long id) {
        return bookingRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy đơn đặt xe với ID: " + id));
    }
}

