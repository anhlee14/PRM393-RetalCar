package com.autorental.backend.model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "gps_check_quotas", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"booking_id", "owner_id", "check_date"})
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class GpsQuota {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "booking_id", nullable = false)
    private Booking booking;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "owner_id", nullable = false)
    private User owner;

    @Column(name = "check_date", nullable = false)
    private LocalDate checkDate;

    // Giới hạn tối đa 20 lần / ngày
    @Column(nullable = false)
    @Builder.Default
    private Integer checkCount = 0;

    @UpdateTimestamp
    private LocalDateTime updatedAt;
}

