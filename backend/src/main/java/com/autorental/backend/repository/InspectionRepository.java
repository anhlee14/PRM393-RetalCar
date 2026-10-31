package com.autorental.backend.repository;

import com.autorental.backend.model.Inspection;
import com.autorental.backend.model.InspectionStage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface InspectionRepository extends JpaRepository<Inspection, Long> {
    List<Inspection> findByBookingId(Long bookingId);
    Optional<Inspection> findByBookingIdAndStage(Long bookingId, InspectionStage stage);
}

