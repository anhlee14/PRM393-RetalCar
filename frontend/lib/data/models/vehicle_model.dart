class VehicleModel {
  final int id;
  final String name;
  final String brand;
  final int? modelYear;
  final String licensePlate;
  final String vehicleType;
  final String transmission;
  final String fuelType;
  final double basePricePerDay;

  // Feature 1: Cấu hình có lái xe
  final bool hasDriverOption;
  final double driverFeePerDay;

  final int seats;
  final String? description;
  final String? address;
  final double? currentLat;
  final double? currentLng;
  final double averageRating;
  final int totalReviews;
  final String status;
  final String? thumbnailUrl;

  VehicleModel({
    required this.id,
    required this.name,
    required this.brand,
    this.modelYear,
    required this.licensePlate,
    required this.vehicleType,
    required this.transmission,
    required this.fuelType,
    required this.basePricePerDay,
    required this.hasDriverOption,
    required this.driverFeePerDay,
    this.seats = 4,
    this.description,
    this.address,
    this.currentLat,
    this.currentLng,
    this.averageRating = 5.0,
    this.totalReviews = 0,
    required this.status,
    this.thumbnailUrl,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      modelYear: json['model_year'],
      licensePlate: json['license_plate'] ?? '',
      vehicleType: json['vehicle_type'] ?? 'SEDAN',
      transmission: json['transmission'] ?? 'AUTO',
      fuelType: json['fuel_type'] ?? 'PETROL',
      basePricePerDay: (json['base_price_per_day'] as num?)?.toDouble() ?? 0.0,
      hasDriverOption: json['has_driver_option'] ?? false,
      driverFeePerDay: (json['driver_fee_per_day'] as num?)?.toDouble() ?? 0.0,
      seats: json['seats'] ?? 4,
      description: json['description'],
      address: json['address'],
      currentLat: (json['current_lat'] as num?)?.toDouble(),
      currentLng: (json['current_lng'] as num?)?.toDouble(),
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 5.0,
      totalReviews: json['total_reviews'] ?? 0,
      status: json['status'] ?? 'AVAILABLE',
      thumbnailUrl: json['thumbnail_url'],
    );
  }
}

