package com.autorental.backend.controller;

import com.autorental.backend.dto.request.BookingRequest;
import com.autorental.backend.dto.response.ApiResponse;
import com.autorental.backend.model.Booking;
import com.autorental.backend.model.User;
import com.autorental.backend.service.AuthService;
import com.autorental.backend.service.BookingService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/bookings")
@RequiredArgsConstructor
public class BookingController {

    private final BookingService bookingService;
    private final AuthService authService;

    // Feature 1: Đặt xe (có tùy chọn kèm tài xế)
    @PostMapping
    public ResponseEntity<ApiResponse<Booking>> createBooking(@Valid @RequestBody BookingRequest request) {
        User renter = authService.getCurrentUser();
        Booking booking = bookingService.createBooking(renter, request);
        return ResponseEntity.ok(ApiResponse.success("Tạo yêu cầu thuê xe thành công", booking));
    }

    // Chủ xe duyệt đơn đặt
    @PutMapping("/{id}/confirm")
    public ResponseEntity<ApiResponse<Booking>> confirmBooking(@PathVariable Long id) {
        User owner = authService.getCurrentUser();
        Booking booking = bookingService.confirmBooking(id, owner);
        return ResponseEntity.ok(ApiResponse.success("Duyệt đơn thuê xe thành công", booking));
    }

    // Bắt đầu chuyến đi
    @PutMapping("/{id}/start")
    public ResponseEntity<ApiResponse<Booking>> startTrip(@PathVariable Long id) {
        Booking booking = bookingService.startTrip(id);
        return ResponseEntity.ok(ApiResponse.success("Bắt đầu chuyến đi thành công", booking));
    }

    // Hoàn thành chuyến đi
    @PutMapping("/{id}/complete")
    public ResponseEntity<ApiResponse<Booking>> completeBooking(@PathVariable Long id) {
        Booking booking = bookingService.completeBooking(id);
        return ResponseEntity.ok(ApiResponse.success("Hoàn thành chuyến xe thành công", booking));
    }

    @GetMapping("/renter")
    public ResponseEntity<ApiResponse<List<Booking>>> getRenterBookings() {
        User renter = authService.getCurrentUser();
        List<Booking> list = bookingService.getRenterBookings(renter.getId());
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách đơn thuê của bạn thành công", list));
    }

    @GetMapping("/owner")
    public ResponseEntity<ApiResponse<List<Booking>>> getOwnerBookings() {
        User owner = authService.getCurrentUser();
        List<Booking> list = bookingService.getOwnerBookings(owner.getId());
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách đơn thuê xe của bạn thành công", list));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Booking>> getBookingById(@PathVariable Long id) {
        Booking booking = bookingService.getBookingById(id);
        return ResponseEntity.ok(ApiResponse.success("Lấy chi tiết đơn thuê xe thành công", booking));
    }
}

