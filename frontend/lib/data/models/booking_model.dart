import 'vehicle_model.dart';
import 'user_model.dart';

class BookingModel {
  final int id;
  final UserModel? renter;
  final VehicleModel? vehicle;
  final String startDate;
  final String endDate;

  // Feature 1: Thuê kèm tài xế
  final bool withDriver;
  final double carRentalPrice;
  final double driverServicePrice;
  final double totalPrice;
  final double depositAmount;

  final String status;
  final String? pickupAddress;
  final String? returnAddress;
  final String? lastRenterGpsPing;

  BookingModel({
    required this.id,
    this.renter,
    this.vehicle,
    required this.startDate,
    required this.endDate,
    required this.withDriver,
    required this.carRentalPrice,
    required this.driverServicePrice,
    required this.totalPrice,
    required this.depositAmount,
    required this.status,
    this.pickupAddress,
    this.returnAddress,
    this.lastRenterGpsPing,
  });

  DateTime? get parsedStartDate => DateTime.tryParse(startDate);
  DateTime? get parsedEndDate => DateTime.tryParse(endDate);

  int get rentalDays {
    if (parsedStartDate == null || parsedEndDate == null) return 1;
    final diff = parsedEndDate!.difference(parsedStartDate!).inDays;
    return diff <= 0 ? 1 : diff;
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] ?? 0,
      renter: json['renter'] != null ? UserModel.fromJson(json['renter']) : null,
      vehicle: json['vehicle'] != null ? VehicleModel.fromJson(json['vehicle']) : null,
      startDate: json['start_date'] ?? json['startDate'] ?? '',
      endDate: json['end_date'] ?? json['endDate'] ?? '',
      withDriver: json['with_driver'] ?? json['withDriver'] ?? false,
      carRentalPrice: (json['car_rental_price'] ?? json['carRentalPrice'] as num?)?.toDouble() ?? 0.0,
      driverServicePrice: (json['driver_service_price'] ?? json['driverServicePrice'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['total_price'] ?? json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      depositAmount: (json['deposit_amount'] ?? json['depositAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'PENDING',
      pickupAddress: json['pickup_address'] ?? json['pickupAddress'],
      returnAddress: json['return_address'] ?? json['returnAddress'],
      lastRenterGpsPing: json['last_renter_gps_ping'] ?? json['lastRenterGpsPing'],
    );
  }
}
