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
      recordedAt: (json['recorded_at'] ?? json['recordedAt'] ?? '').toString(),
    );
  }
}

class GpsSnapshotModel {
  final int bookingId;
  final String bookingStatus;
  final String vehicleName;
  final double latitude;
  final double longitude;
  final double speed;
  final String recordedAt;

  // Feature 2: Quota 20 lần / ngày
  final int remainingChecksToday;
  final int totalAllowedPerDay;
  final bool quotaConsumed;

  GpsSnapshotModel({
    required this.bookingId,
    this.bookingStatus = 'ONGOING',
    required this.vehicleName,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.recordedAt,
    required this.remainingChecksToday,
    required this.totalAllowedPerDay,
    this.quotaConsumed = true,
  });

  factory GpsSnapshotModel.fromJson(Map<String, dynamic> json) {
    return GpsSnapshotModel(
      bookingId: json['booking_id'] ?? json['bookingId'] ?? 0,
      bookingStatus: (json['booking_status'] ?? json['bookingStatus'] ?? 'ONGOING').toString(),
      vehicleName: (json['vehicle_name'] ?? json['vehicleName'] ?? '').toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      recordedAt: (json['recorded_at'] ?? json['recordedAt'] ?? '').toString(),
      remainingChecksToday: json['remaining_checks_today'] ?? json['remainingChecksToday'] ?? 20,
      totalAllowedPerDay: json['total_allowed_per_day'] ?? json['totalAllowedPerDay'] ?? 20,
      quotaConsumed: json['quota_consumed'] ?? json['quotaConsumed'] ?? true,
    );
  }
}
