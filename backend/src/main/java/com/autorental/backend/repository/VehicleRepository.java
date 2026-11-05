package com.autorental.backend.repository;

import com.autorental.backend.model.Vehicle;
import com.autorental.backend.model.VehicleStatus;
import com.autorental.backend.model.VehicleType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface VehicleRepository extends JpaRepository<Vehicle, Long> {
    List<Vehicle> findByOwnerId(Long ownerId);
    List<Vehicle> findByStatus(VehicleStatus status);
    boolean existsByLicensePlate(String licensePlate);
    boolean existsByLicensePlateAndIdNot(String licensePlate, Long id);

    @Query("SELECT v FROM Vehicle v WHERE v.status = :status " +
           "AND (:vehicleType IS NULL OR v.vehicleType = :vehicleType) " +
           "AND (:hasDriver IS NULL OR v.hasDriverOption = :hasDriver)")
    List<Vehicle> searchVehicles(@Param("status") VehicleStatus status,
                                 @Param("vehicleType") VehicleType vehicleType,
                                 @Param("hasDriver") Boolean hasDriver);
}
