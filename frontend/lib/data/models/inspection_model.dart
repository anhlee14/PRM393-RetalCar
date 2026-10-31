class InspectionModel {
  final int id;
  final int bookingId;
  final String stage; // CHECK_IN, CHECK_OUT
  final String? frontImg;
  final String? rearImg;
  final String? leftImg;
  final String? rightImg;
  final String? odoImg;
  final String? fuelImg;
  final double? odoKm;
  final double? fuelLevelPercent;
  final String? notes;
  final bool isConfirmedByRenter;
  final bool isConfirmedByOwner;

  InspectionModel({
    required this.id,
    required this.bookingId,
    required this.stage,
    this.frontImg,
    this.rearImg,
    this.leftImg,
    this.rightImg,
    this.odoImg,
    this.fuelImg,
    this.odoKm,
    this.fuelLevelPercent,
    this.notes,
    required this.isConfirmedByRenter,
    required this.isConfirmedByOwner,
  });

  factory InspectionModel.fromJson(Map<String, dynamic> json) {
    return InspectionModel(
      id: json['id'] ?? 0,
      bookingId: json['booking_id'] ?? (json['booking'] != null ? json['booking']['id'] : 0),
      stage: json['stage'] ?? 'CHECK_IN',
      frontImg: json['front_img'],
      rearImg: json['rear_img'],
      leftImg: json['left_img'],
      rightImg: json['right_img'],
      odoImg: json['odo_img'],
      fuelImg: json['fuel_img'],
      odoKm: (json['odo_km'] as num?)?.toDouble(),
      fuelLevelPercent: (json['fuel_level_percent'] as num?)?.toDouble(),
      notes: json['notes'],
      isConfirmedByRenter: json['is_confirmed_by_renter'] ?? false,
      isConfirmedByOwner: json['is_confirmed_by_owner'] ?? false,
    );
  }
}

class InspectionComparisonModel {
  final int bookingId;
  final String vehicleName;
  final String licensePlate;
  final InspectionModel? checkIn;
  final InspectionModel? checkOut;
  final double odoDifferenceKm;
  final double fuelDifferencePercent;
  final bool isFullyConfirmed;

  InspectionComparisonModel({
    required this.bookingId,
    required this.vehicleName,
    required this.licensePlate,
    this.checkIn,
    this.checkOut,
    required this.odoDifferenceKm,
    required this.fuelDifferencePercent,
    required this.isFullyConfirmed,
  });

  factory InspectionComparisonModel.fromJson(Map<String, dynamic> json) {
    return InspectionComparisonModel(
      bookingId: json['booking_id'] ?? 0,
      vehicleName: json['vehicle_name'] ?? '',
      licensePlate: json['license_plate'] ?? '',
      checkIn: json['check_in'] != null ? InspectionModel.fromJson(json['check_in']) : null,
      checkOut: json['check_out'] != null ? InspectionModel.fromJson(json['check_out']) : null,
      odoDifferenceKm: (json['odo_difference_km'] as num?)?.toDouble() ?? 0.0,
      fuelDifferencePercent: (json['fuel_difference_percent'] as num?)?.toDouble() ?? 0.0,
      isFullyConfirmed: json['is_fully_confirmed'] ?? false,
    );
  }
}

