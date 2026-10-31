package com.autorental.backend.model;

public enum NotificationType {
    GPS_WARNING,         // Cảnh báo quá 1h chưa ping GPS
    BOOKING_STATUS,      // Cập nhật duyệt/hủy đơn
    INSPECTION_UPDATE,   // Cập nhật biên bản giao nhận xe
    PAYMENT_UPDATE,      // Cập nhật thanh toán / cọc
    SYSTEM
}

