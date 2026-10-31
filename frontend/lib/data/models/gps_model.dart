class GpsLogModel {
  final int id;
  final double latitude;
  final double longitude;
  final double speed;
  final String recordedAt;

  GpsLogModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.recordedAt,
  });

  factory GpsLogModel.fromJson(Map<String, dynamic> json) {
    return GpsLogModel(
      id: json['id'] ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      recordedAt: json['recorded_at'] ?? '',
    );
  }
}

class GpsSnapshotModel {
  final int bookingId;
  final String vehicleName;
  final double latitude;
  final double longitude;
  final double speed;
  final String recordedAt;

  // Feature 2: Quota 20 lần / ngày
  final int remainingChecksToday;
  final int totalAllowedPerDay;

  GpsSnapshotModel({
    required this.bookingId,
    required this.vehicleName,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.recordedAt,
    required this.remainingChecksToday,
    required this.totalAllowedPerDay,
  });

  factory GpsSnapshotModel.fromJson(Map<String, dynamic> json) {
    return GpsSnapshotModel(
      bookingId: json['booking_id'] ?? 0,
      vehicleName: json['vehicle_name'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      recordedAt: json['recorded_at'] ?? '',
      remainingChecksToday: json['remaining_checks_today'] ?? 20,
      totalAllowedPerDay: json['total_allowed_per_day'] ?? 20,
    );
  }
}

