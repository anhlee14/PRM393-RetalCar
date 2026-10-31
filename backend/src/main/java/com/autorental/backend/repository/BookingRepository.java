package com.autorental.backend.repository;

import com.autorental.backend.model.Booking;
import com.autorental.backend.model.BookingStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BookingRepository extends JpaRepository<Booking, Long> {
    List<Booking> findByRenterId(Long renterId);
    List<Booking> findByVehicleOwnerId(Long ownerId);
    List<Booking> findByVehicleIdAndStatus(Long vehicleId, BookingStatus status);
    List<Booking> findByStatus(BookingStatus status);
}

