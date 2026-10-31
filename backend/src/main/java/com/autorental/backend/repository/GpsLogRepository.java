package com.autorental.backend.repository;

import com.autorental.backend.model.GpsLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface GpsLogRepository extends JpaRepository<GpsLog, Long> {
    List<GpsLog> findByBookingIdOrderByRecordedAtAsc(Long bookingId);
    Optional<GpsLog> findFirstByBookingIdOrderByRecordedAtDesc(Long bookingId);
}

