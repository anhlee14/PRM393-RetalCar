import '../../core/constants/api_endpoints.dart';
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

  static String? _resolveUrl(dynamic url) {
    if (url == null) return null;
    final str = url.toString().trim();
    if (str.isEmpty) return null;
    if (str.startsWith('/uploads/')) {
      return '${ApiEndpoints.baseUrl}$str';
    }
    return str;
  }

  factory InspectionModel.fromJson(Map<String, dynamic> json) {
    return InspectionModel(
      id: json['id'] ?? 0,
      bookingId: json['booking_id'] ?? json['bookingId'] ?? (json['booking'] != null ? json['booking']['id'] : 0),
      stage: json['stage'] ?? 'CHECK_IN',
      frontImg: _resolveUrl(json['front_img'] ?? json['frontImg']),
      rearImg: _resolveUrl(json['rear_img'] ?? json['rearImg']),
      leftImg: _resolveUrl(json['left_img'] ?? json['leftImg']),
      rightImg: _resolveUrl(json['right_img'] ?? json['rightImg']),
      odoImg: _resolveUrl(json['odo_img'] ?? json['odoImg']),
      fuelImg: _resolveUrl(json['fuel_img'] ?? json['fuelImg']),
      odoKm: (json['odo_km'] ?? json['odoKm'] as num?)?.toDouble(),
      fuelLevelPercent: (json['fuel_level_percent'] ?? json['fuelLevelPercent'] as num?)?.toDouble(),
      notes: json['notes'],
      isConfirmedByRenter: json['is_confirmed_by_renter'] ?? json['isConfirmedByRenter'] ?? false,
      isConfirmedByOwner: json['is_confirmed_by_owner'] ?? json['isConfirmedByOwner'] ?? false,
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
      bookingId: json['booking_id'] ?? json['bookingId'] ?? 0,
      vehicleName: json['vehicle_name'] ?? json['vehicleName'] ?? '',
      licensePlate: json['license_plate'] ?? json['licensePlate'] ?? '',
      checkIn: json['check_in'] != null
          ? InspectionModel.fromJson(json['check_in'])
          : (json['checkIn'] != null ? InspectionModel.fromJson(json['checkIn']) : null),
      checkOut: json['check_out'] != null
          ? InspectionModel.fromJson(json['check_out'])
          : (json['checkOut'] != null ? InspectionModel.fromJson(json['checkOut']) : null),
      odoDifferenceKm: (json['odo_difference_km'] ?? json['odoDifferenceKm'] as num?)?.toDouble() ?? 0.0,
      fuelDifferencePercent: (json['fuel_difference_percent'] ?? json['fuelDifferencePercent'] as num?)?.toDouble() ?? 0.0,
      isFullyConfirmed: json['is_fully_confirmed'] ?? json['isFullyConfirmed'] ?? false,
    );
  }
}
