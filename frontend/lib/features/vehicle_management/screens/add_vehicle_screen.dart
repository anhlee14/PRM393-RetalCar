import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/vehicle_service.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _yearController = TextEditingController(text: '2024');
  final _priceController = TextEditingController();
  final _driverFeeController = TextEditingController(text: '300000');
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _thumbnailController = TextEditingController(
    text: 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341',
  );

  String _selectedBrand = 'VinFast';
  String _selectedType = 'SEDAN';
  String _selectedTransmission = 'AUTO';
  String _selectedFuel = 'PETROL';
  int _selectedSeats = 5;

  // Feature 1: Nghiệp vụ đặc thù 1 - Tùy chọn kèm tài xế
  bool _hasDriverOption = true;
  bool _isLoading = false;

  final List<String> _brands = [
    'VinFast',
    'Toyota',
    'Hyundai',
    'Mazda',
    'Honda',
    'Kia',
    'Ford',
    'Mitsubishi',
    'Mercedes-Benz',
    'BMW',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _licensePlateController.dispose();
    _yearController.dispose();
    _priceController.dispose();
    _driverFeeController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _thumbnailController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final basePrice = double.tryParse(_priceController.text.trim());
    if (basePrice == null || basePrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giá thuê tự lái phải lớn hơn 0'), backgroundColor: AppColors.danger),
      );
      return;
    }

    double driverFee = 0;
    if (_hasDriverOption) {
      driverFee = double.tryParse(_driverFeeController.text.trim()) ?? 0;
      if (driverFee <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phụ phí tài xế phải lớn hơn 0 khi bật tùy chọn tài xế'), backgroundColor: AppColors.danger),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    final res = await VehicleService.createVehicle(
      name: _nameController.text.trim(),
      brand: _selectedBrand,
      licensePlate: _licensePlateController.text.trim().toUpperCase(),
      vehicleType: _selectedType,
      transmission: _selectedTransmission,
      fuelType: _selectedFuel,
      basePricePerDay: basePrice,
      hasDriverOption: _hasDriverOption,
      driverFeePerDay: driverFee,
      seats: _selectedSeats,
      modelYear: int.tryParse(_yearController.text.trim()) ?? 2024,
      description: _descriptionController.text.trim(),
      address: _addressController.text.trim(),
      thumbnailUrl: _thumbnailController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng ký xe thành công! Xe đang ở trạng thái "Chờ Admin duyệt" trước khi mở cho thuê.'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 4),
        ),
      );
      Navigator.pop(context, true); // Trả về true để màn hình danh sách tự refresh
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Đăng xe thất bại'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  // Chọn ảnh mẫu nhanh giúp demo dễ dàng
  void _setSampleImage(String url) {
    setState(() {
      _thumbnailController.text = url;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng Xe Mới Cho Thuê'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thông tin cơ bản
              const Text(
                '1. Thông Tin Xe',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên xe * (VD: VinFast VF8 Plus, Mazda CX-5)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.directions_car),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Vui lòng nhập tên xe' : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedBrand,
                      decoration: const InputDecoration(
                        labelText: 'Hãng xe *',
                        border: OutlineInputBorder(),
                      ),
                      items: _brands.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                      onChanged: (val) => setState(() => _selectedBrand = val!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _licensePlateController,
                      decoration: const InputDecoration(
                        labelText: 'Biển số * (VD: 30K-888.88)',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Nhập biển số' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Loại xe',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'SEDAN', child: Text('Sedan')),
                        DropdownMenuItem(value: 'SUV', child: Text('SUV / Crossover')),
                        DropdownMenuItem(value: 'MPV', child: Text('MPV 7 chỗ')),
                        DropdownMenuItem(value: 'HATCHBACK', child: Text('Hatchback')),
                        DropdownMenuItem(value: 'PICKUP', child: Text('Bán tải')),
                      ],
                      onChanged: (val) => setState(() => _selectedType = val!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _selectedSeats,
                      decoration: const InputDecoration(
                        labelText: 'Số chỗ ngồi',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 4, child: Text('4 chỗ')),
                        DropdownMenuItem(value: 5, child: Text('5 chỗ')),
                        DropdownMenuItem(value: 7, child: Text('7 chỗ')),
                      ],
                      onChanged: (val) => setState(() => _selectedSeats = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedTransmission,
                      decoration: const InputDecoration(
                        labelText: 'Hộp số',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'AUTO', child: Text('Tự động (Auto)')),
                        DropdownMenuItem(value: 'MANUAL', child: Text('Số sàn (Manual)')),
                      ],
                      onChanged: (val) => setState(() => _selectedTransmission = val!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedFuel,
                      decoration: const InputDecoration(
                        labelText: 'Nhiên liệu',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'PETROL', child: Text('Xăng')),
                        DropdownMenuItem(value: 'DIESEL', child: Text('Dầu')),
                        DropdownMenuItem(value: 'ELECTRIC', child: Text('Điện')),
                        DropdownMenuItem(value: 'HYBRID', child: Text('Hybrid')),
                      ],
                      onChanged: (val) => setState(() => _selectedFuel = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _yearController,
                      decoration: const InputDecoration(
                        labelText: 'Năm sản xuất',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ nhận xe (VD: Hòa Lạc, Hà Nội)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Nhập địa chỉ giao nhận' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Giá thuê & Phụ phí tài xế (Feature 1)
              const Text(
                '2. Thiết Lập Giá & Dịch Vụ Tài Xế (Nghiệp vụ đặc thù 1)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Giá thuê xe tự lái / ngày (VNĐ) *',
                  hintText: 'VD: 800000',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payments_outlined),
                  suffixText: 'đ/ngày',
                ),
                keyboardType: TextInputType.number,
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Vui lòng nhập giá thuê' : null,
              ),
              const SizedBox(height: 14),

              // Card nghiệp vụ đặc thù 1: Switch có tài xế
              Card(
                elevation: 0,
                color: _hasDriverOption ? Colors.deepPurple.shade50 : Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _hasDriverOption ? Colors.deepPurple.shade200 : Colors.grey.shade300,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Hỗ trợ kèm tài xế riêng',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          'Cho phép khách chọn thuê xe có tài xế lái đưa đón',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        value: _hasDriverOption,
                        activeThumbColor: Colors.deepPurple,
                        onChanged: (val) {
                          setState(() {
                            _hasDriverOption = val;
                          });
                        },
                      ),
                      if (_hasDriverOption) ...[
                        const Divider(),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _driverFeeController,
                          decoration: const InputDecoration(
                            labelText: 'Phụ phí công tài xế / ngày (VNĐ) *',
                            hintText: 'VD: 300000',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_pin, color: Colors.deepPurple),
                            suffixText: 'đ/ngày',
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            if (_hasDriverOption && (val == null || val.trim().isEmpty)) {
                              return 'Nhập phụ phí tài xế';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Hình ảnh & Mô tả
              const Text(
                '3. Hình Ảnh & Mô Tả',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _thumbnailController,
                decoration: const InputDecoration(
                  labelText: 'URL Ảnh xe đại diện (Thumbnail)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.image_outlined),
                ),
              ),
              const SizedBox(height: 8),

              // Gợi ý ảnh nhanh
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('VF8 Trắng'),
                    onPressed: () => _setSampleImage('https://images.unsplash.com/photo-1549399542-7e3f8b79c341'),
                  ),
                  ActionChip(
                    label: const Text('SUV Đỏ'),
                    onPressed: () => _setSampleImage('https://images.unsplash.com/photo-1533473359331-0135ef1b58bf'),
                  ),
                  ActionChip(
                    label: const Text('Sedan Đen'),
                    onPressed: () => _setSampleImage('https://images.unsplash.com/photo-1552519507-da3b142c6e3d'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Mô tả tiện nghi (Cửa sổ trời, sạc không dây, bảo dưỡng định kỳ...)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 28),

              // Nút Đăng xe
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleSubmit,
                icon: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.add_circle_outline),
                label: Text(
                  _isLoading ? 'ĐANG ĐĂNG XE...' : 'ĐĂNG XE NGAY',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
