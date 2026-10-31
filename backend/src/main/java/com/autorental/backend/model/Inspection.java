package com.autorental.backend.model;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "inspections")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Inspection {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "booking_id", nullable = false)
    private Booking booking;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private InspectionStage stage; // CHECK_IN hoặc CHECK_OUT

    // 6 góc chụp tiêu chuẩn
    private String frontImg;
    private String rearImg;
    private String leftImg;
    private String rightImg;
    private String odoImg;
    private String fuelImg;

    private Double odoKm;
    private Double fuelLevelPercent;

    @Column(length = 1000)
    private String notes;

    @Builder.Default
    private Boolean isConfirmedByRenter = false;

    @Builder.Default
    private Boolean isConfirmedByOwner = false;

    private LocalDateTime confirmedAt;

    @CreationTimestamp
    private LocalDateTime createdAt;
}

