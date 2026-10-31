package com.autorental.backend.repository;

import com.autorental.backend.model.GpsQuota;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.Optional;

@Repository
public interface GpsQuotaRepository extends JpaRepository<GpsQuota, Long> {
    Optional<GpsQuota> findByBookingIdAndOwnerIdAndCheckDate(Long bookingId, Long ownerId, LocalDate checkDate);
}

