import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:car_rental_app/data/models/booking_model.dart';
import 'package:car_rental_app/data/models/inspection_model.dart';
import 'package:car_rental_app/data/models/vehicle_model.dart';
import 'package:car_rental_app/features/booking/screens/booking_form_screen.dart';
import 'package:car_rental_app/features/booking/screens/checkout_payment_screen.dart';
import 'package:car_rental_app/features/booking/screens/booking_history_screen.dart';
import 'package:car_rental_app/features/inspection/screens/photo_inspection_screen.dart';
import 'package:car_rental_app/features/inspection/screens/comparison_screen.dart';
import 'package:car_rental_app/features/inspection/screens/checkin_review_screen.dart';
import 'package:car_rental_app/features/matching_explore/screens/vehicle_detail_screen.dart';

void main() {
  group('1. BookingModel Unit Tests', () {
    test('Parse BookingModel from snake_case JSON correctly', () {
      final json = {
        'id': 101,
        'start_date': '2026-11-05T08:00:00',
        'end_date': '2026-11-08T20:00:00',
        'with_driver': true,
        'car_rental_price': 3000000.0,
        'driver_service_price': 1500000.0,
        'total_price': 4500000.0,
        'deposit_amount': 1350000.0,
        'status': 'CONFIRMED',
        'pickup_address': 'Hà Nội',
        'return_address': 'Hà Nội',
      };

      final booking = BookingModel.fromJson(json);

      expect(booking.id, 101);
      expect(booking.withDriver, isTrue);
      expect(booking.totalPrice, 4500000.0);
      expect(booking.depositAmount, 1350000.0);
      expect(booking.status, 'CONFIRMED');
      expect(booking.rentalDays, 3);
    });

    test('Parse BookingModel with fallback camelCase JSON', () {
      final json = {
        'id': 102,
        'startDate': '2026-11-10T08:00:00',
        'endDate': '2026-11-12T08:00:00',
        'withDriver': false,
        'carRentalPrice': 1600000.0,
        'totalPrice': 1600000.0,
        'depositAmount': 480000.0,
        'status': 'PENDING',
      };

      final booking = BookingModel.fromJson(json);

      expect(booking.id, 102);
      expect(booking.withDriver, isFalse);
      expect(booking.rentalDays, 2);
      expect(booking.depositAmount, 480000.0);
    });
  });

  group('2. InspectionModel Unit Tests', () {
    test('Parse InspectionModel correctly', () {
      final json = {
        'id': 201,
        'booking_id': 101,
        'stage': 'CHECK_IN',
        'front_img': 'https://example.com/front.jpg',
        'odo_km': 15200.0,
        'fuel_level_percent': 100.0,
        'notes': 'Xe mới và sạch sẽ',
        'is_confirmed_by_renter': true,
        'is_confirmed_by_owner': false,
      };

      final insp = InspectionModel.fromJson(json);

      expect(insp.id, 201);
      expect(insp.bookingId, 101);
      expect(insp.stage, 'CHECK_IN');
      expect(insp.odoKm, 15200.0);
      expect(insp.fuelLevelPercent, 100.0);
      expect(insp.isConfirmedByRenter, isTrue);
      expect(insp.isConfirmedByOwner, isFalse);
    });

    test('Parse InspectionComparisonModel and difference calculations', () {
      final json = {
        'booking_id': 101,
        'vehicle_name': 'VinFast VF8',
        'license_plate': '30K-999.88',
        'check_in': {
          'id': 1,
          'booking_id': 101,
          'stage': 'CHECK_IN',
          'odo_km': 15000.0,
          'fuel_level_percent': 100.0,
          'is_confirmed_by_renter': true,
          'is_confirmed_by_owner': true,
        },
        'check_out': {
          'id': 2,
          'booking_id': 101,
          'stage': 'CHECK_OUT',
          'odo_km': 15250.0,
          'fuel_level_percent': 85.0,
          'is_confirmed_by_renter': true,
          'is_confirmed_by_owner': true,
        },
        'odo_difference_km': 250.0,
        'fuel_difference_percent': -15.0,
        'is_fully_confirmed': true,
      };

      final comp = InspectionComparisonModel.fromJson(json);

      expect(comp.bookingId, 101);
      expect(comp.vehicleName, 'VinFast VF8');
      expect(comp.odoDifferenceKm, 250.0);
      expect(comp.fuelDifferencePercent, -15.0);
      expect(comp.isFullyConfirmed, isTrue);
    });
  });

  group('3. BookingFormScreen Widget Tests', () {
    testWidgets('Renders BookingFormScreen with vehicle info and driver toggle', (tester) async {
      final testVehicle = VehicleModel(
        id: 1,
        name: 'VinFast VF8 Eco',
        brand: 'VinFast',
        licensePlate: '30K-999.88',
        vehicleType: 'SUV',
        transmission: 'AUTO',
        fuelType: 'ELECTRIC',
        basePricePerDay: 1200000,
        hasDriverOption: true,
        driverFeePerDay: 500000,
        status: 'AVAILABLE',
        address: 'Hà Nội',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BookingFormScreen(vehicle: testVehicle),
        ),
      );
      await tester.pump();

      // Verify header and vehicle summary
      expect(find.text('Cấu Hình Đặt Xe'), findsOneWidget);
      expect(find.text('VinFast VF8 Eco'), findsOneWidget);
      expect(find.text('30K-999.88'), findsOneWidget);

      // Verify date range & driver toggle
      expect(find.text('Thời gian thuê xe'), findsOneWidget);
      expect(find.text('Thuê kèm tài xế riêng'), findsOneWidget);

      // Verify action button
      expect(find.text('TIẾP TỤC ĐẾN THANH TOÁN CỌC'), findsOneWidget);
    });
  });

  group('4. CheckoutPaymentScreen Widget Tests', () {
    testWidgets('Renders CheckoutPaymentScreen with VietQR and deposit amount', (tester) async {
      final testBooking = BookingModel(
        id: 88,
        startDate: '2026-11-05',
        endDate: '2026-11-07',
        withDriver: true,
        carRentalPrice: 2400000,
        driverServicePrice: 1000000,
        totalPrice: 3400000,
        depositAmount: 1020000,
        status: 'PENDING',
        vehicle: VehicleModel(
          id: 1,
          name: 'VinFast VF8 Eco',
          brand: 'VinFast',
          licensePlate: '30K-999.88',
          vehicleType: 'SUV',
          transmission: 'AUTO',
          fuelType: 'ELECTRIC',
          basePricePerDay: 1200000,
          hasDriverOption: true,
          driverFeePerDay: 500000,
          status: 'AVAILABLE',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CheckoutPaymentScreen(booking: testBooking),
        ),
      );
      await tester.pump();

      // Header and Code
      expect(find.text('Hóa Đơn & Đặt Cọc'), findsOneWidget);
      expect(find.text('#BK-88'), findsOneWidget);

      // Financial breakdown
      expect(find.text('Bảng Kê Hóa Đơn Tài Chính'), findsOneWidget);
      expect(find.text('TIỀN CỌC CẦN THANH TOÁN (30%)'), findsOneWidget);

      // Payment options
      expect(find.text('Phương Thức Thanh Toán'), findsOneWidget);
      expect(find.text('Chuyển khoản QR (VietQR Ngân hàng)'), findsOneWidget);

      // Confirm button
      expect(find.text('XÁC NHẬN ĐÃ THANH TOÁN CỌC'), findsOneWidget);
    });
  });

  group('5. BookingHistoryScreen Widget Tests', () {
    testWidgets('Renders BookingHistoryScreen with tabs', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: BookingHistoryScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Lịch Sử Chuyến Đi & Đơn Thuê'), findsOneWidget);
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Chờ duyệt'), findsOneWidget);
      expect(find.text('Đang đi'), findsOneWidget);
      expect(find.text('Hoàn thành'), findsOneWidget);
    });
  });

  group('6. PhotoInspectionScreen Widget Tests', () {
    testWidgets('Renders PhotoInspectionScreen check-in with 6 standard slots', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PhotoInspectionScreen(bookingId: 88, stage: 'CHECK_IN'),
        ),
      );
      await tester.pump();

      expect(find.text('BIÊN BẢN NHẬN XE (CHECK-IN)'), findsOneWidget);
      expect(find.text('Lưới 6 Góc Chụp Tiêu Chuẩn'), findsOneWidget);
      expect(find.text('1. Đầu xe (Front)'), findsOneWidget);
      expect(find.text('2. Đuôi xe (Rear)'), findsOneWidget);
      expect(find.text('3. Sườn trái (Left Side)'), findsOneWidget);
      expect(find.text('4. Sườn phải (Right Side)'), findsOneWidget);
      expect(find.text('Chỉ Số Đồng Hồ & Nhiên Liệu'), findsOneWidget);
      expect(find.text('GỬI BIÊN BẢN NHẬN XE'), findsOneWidget);
    });

    testWidgets('Renders PhotoInspectionScreen check-out stage', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PhotoInspectionScreen(bookingId: 88, stage: 'CHECK_OUT'),
        ),
      );
      await tester.pump();

      expect(find.text('BIÊN BẢN TRẢ XE (CHECK-OUT)'), findsOneWidget);
      expect(find.text('GỬI BIÊN BẢN TRẢ XE'), findsOneWidget);
    });
  });

  group('7. ComparisonScreen Widget Tests', () {
    testWidgets('Renders ComparisonScreen empty state when loading finished with null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ComparisonScreen(bookingId: 999),
        ),
      );
      await tester.pump();

      expect(find.text('Đối Chiếu Trước & Sau (Before/After)'), findsOneWidget);
    });
  });

  group('8. CheckInReviewScreen Widget Tests', () {
    testWidgets('Renders CheckInReviewScreen empty state when loading finished with null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CheckInReviewScreen(bookingId: 999),
        ),
      );
      await tester.pump();

      expect(find.text('Biên Bản Nhận Xe (Chủ Xe Giao)'), findsOneWidget);
    });
  });


  group('9. VehicleModel & DetailScreen Business Logic Tests', () {
    test('Parse VehicleModel with owner information correctly', () {
      final json = {
        'id': 10,
        'name': 'Toyota Camry 2.5Q',
        'brand': 'Toyota',
        'license_plate': '30F-123.45',
        'vehicle_type': 'SEDAN',
        'transmission': 'AUTO',
        'fuel_type': 'PETROL',
        'base_price_per_day': 1100000.0,
        'has_driver_option': false,
        'driver_fee_per_day': 0.0,
        'status': 'RENTED',
        'owner': {
          'id': 5,
          'full_name': 'Nguyễn Văn Chủ Xe',
          'email': 'owner@gmail.com',
          'phone': '0912345678',
          'role': 'ROLE_OWNER'
        }
      };

      final vehicle = VehicleModel.fromJson(json);
      expect(vehicle.id, 10);
      expect(vehicle.status, 'RENTED');
      expect(vehicle.ownerId, 5);
      expect(vehicle.owner?.fullName, 'Nguyễn Văn Chủ Xe');
    });

    testWidgets('VehicleDetailScreen shows disabled button when vehicle is RENTED', (tester) async {
      final rentedVehicle = VehicleModel(
        id: 11,
        name: 'Mazda CX-5 Premium',
        brand: 'Mazda',
        licensePlate: '30E-555.66',
        vehicleType: 'SUV',
        transmission: 'AUTO',
        fuelType: 'PETROL',
        basePricePerDay: 900000,
        hasDriverOption: false,
        driverFeePerDay: 0,
        status: 'RENTED',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: VehicleDetailScreen(vehicle: rentedVehicle),
        ),
      );
      await tester.pump();

      expect(find.text('XE ĐANG ĐƯỢC THUÊ'), findsOneWidget);
    });

    testWidgets('VehicleDetailScreen shows disabled button when vehicle is in MAINTENANCE', (tester) async {
      final maintenanceVehicle = VehicleModel(
        id: 12,
        name: 'Hyundai SantaFe',
        brand: 'Hyundai',
        licensePlate: '29A-888.88',
        vehicleType: 'SUV',
        transmission: 'AUTO',
        fuelType: 'DIESEL',
        basePricePerDay: 1300000,
        hasDriverOption: true,
        driverFeePerDay: 400000,
        status: 'MAINTENANCE',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: VehicleDetailScreen(vehicle: maintenanceVehicle),
        ),
      );
      await tester.pump();

      expect(find.text('XE ĐANG BẢO DƯỠNG'), findsOneWidget);
    });
  });
}
