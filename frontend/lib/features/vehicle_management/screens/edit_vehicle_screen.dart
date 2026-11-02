import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/vehicle_model.dart';
import '../../../data/services/vehicle_service.dart';

class EditVehicleScreen extends StatefulWidget {
  final VehicleModel vehicle;

  const EditVehicleScreen({super.key, required this.vehicle});

  @override
  State<EditVehicleScreen> createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends State<EditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _licensePlateController;
  late final TextEditingController _yearController;
  late final TextEditingController _priceController;
  late final TextEditingController _driverFeeController;
  late final TextEditingController _addressController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _thumbnailController;

  late String _selectedBrand;
  late String _selectedType;
  late String _selectedTransmission;
  late String _selectedFuel;
  late int _selectedSeats;
  late bool _hasDriverOption;

  bool _isSaving = false;
  bool _isDeleting = false;

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
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _nameController = TextEditingController(text: v.name);
    _licensePlateController = TextEditingController(text: v.licensePlate);
    _yearController = TextEditingController(text: (v.modelYear ?? 2024).toString());
    _priceController = TextEditingController(text: v.basePricePerDay.toInt().toString());
    _driverFeeController = TextEditingController(text: v.driverFeePerDay.toInt().toString());
    _addressController = TextEditingController(text: v.address ?? '');
    _descriptionController = TextEditingController(text: v.description ?? '');
    _thumbnailController = TextEditingController(text: v.thumbnailUrl ?? '');

    _selectedBrand = _brands.contains(v.brand) ? v.brand : 'VinFast';
    _selectedType = v.vehicleType;
    _selectedTransmission = v.transmission;
    _selectedFuel = v.fuelType;
    _selectedSeats = v.seats;
    _hasDriverOption = v.hasDriverOption;
  }

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

  void _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    final basePrice = double.tryParse(_priceController.text.trim());
    if (basePrice == null || basePrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giá thuê phải lớn hơn 0'), backgroundColor: AppColors.danger),
      );
      return;
    }

    double driverFee = 0;
    if (_hasDriverOption) {
      driverFee = double.tryParse(_driverFeeController.text.trim()) ?? 0;
      if (driverFee <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phụ phí tài xế phải lớn hơn 0'), backgroundColor: AppColors.danger),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    final res = await VehicleService.updateVehicle(
      widget.vehicle.id,
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
    setState(() => _isSaving = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật thông tin xe thành công!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Cập nhật thất bại'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa xe'),
        content: Text(
          'Bạn có chắc chắn muốn xóa xe "${widget.vehicle.name} (${widget.vehicle.licensePlate})"?\n\n'
          'Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('XÓA NGAY'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);

    final res = await VehicleService.deleteVehicle(widget.vehicle.id);

    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa xe thành công khỏi hệ thống!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Không thể xóa xe (có thể xe đang có đơn thuê active).'),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh Sửa Thông Tin Xe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.white),
            tooltip: 'Xóa xe này',
            onPressed: _isDeleting ? null : _handleDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thông tin xe
              const Text(
                '1. Thông Tin Cơ Bản',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên xe *',
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
                      decoration: const InputDecoration(labelText: 'Hãng xe', border: OutlineInputBorder()),
                      items: _brands.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                      onChanged: (val) => setState(() => _selectedBrand = val!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _licensePlateController,
                      decoration: const InputDecoration(labelText: 'Biển số', border: OutlineInputBorder()),
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
                      decoration: const InputDecoration(labelText: 'Loại xe', border: OutlineInputBorder()),
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
                      decoration: const InputDecoration(labelText: 'Số chỗ', border: OutlineInputBorder()),
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
                      decoration: const InputDecoration(labelText: 'Hộp số', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'AUTO', child: Text('Tự động')),
                        DropdownMenuItem(value: 'MANUAL', child: Text('Số sàn')),
                      ],
                      onChanged: (val) => setState(() => _selectedTransmission = val!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedFuel,
                      decoration: const InputDecoration(labelText: 'Nhiên liệu', border: OutlineInputBorder()),
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
                      decoration: const InputDecoration(labelText: 'Năm sản xuất', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Địa chỉ nhận xe', border: OutlineInputBorder()),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Nhập địa chỉ' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Thiết lập giá & Feature 1
              const Text(
                '2. Giá Thuê & Dịch Vụ Tài Xế (Nghiệp vụ đặc thù 1)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Giá thuê tự lái / ngày (VNĐ) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payments_outlined),
                  suffixText: 'đ/ngày',
                ),
                keyboardType: TextInputType.number,
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Nhập giá thuê' : null,
              ),
              const SizedBox(height: 14),

              Card(
                elevation: 0,
                color: _hasDriverOption ? Colors.deepPurple.shade50 : Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: _hasDriverOption ? Colors.deepPurple.shade200 : Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Hỗ trợ kèm tài xế riêng', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Cho phép khách chọn thuê xe có tài xế lái đưa đón', style: TextStyle(fontSize: 12)),
                        value: _hasDriverOption,
                        activeThumbColor: Colors.deepPurple,
                        onChanged: (val) => setState(() => _hasDriverOption = val),
                      ),
                      if (_hasDriverOption) ...[
                        const Divider(),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _driverFeeController,
                          decoration: const InputDecoration(
                            labelText: 'Phụ phí tài xế / ngày (VNĐ) *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_pin, color: Colors.deepPurple),
                            suffixText: 'đ/ngày',
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (val) => (_hasDriverOption && (val == null || val.trim().isEmpty)) ? 'Nhập phụ phí tài xế' : null,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Ảnh & Mô tả
              const Text('3. Ảnh & Mô Tả', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const SizedBox(height: 12),

              TextFormField(
                controller: _thumbnailController,
                decoration: const InputDecoration(labelText: 'URL Ảnh xe', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Mô tả tiện nghi', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 28),

              // Nút Lưu thay đổi
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _handleUpdate,
                icon: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _isSaving ? 'ĐANG LƯU...' : 'LƯU THAY ĐỔI',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),

              // Nút Xóa xe
              OutlinedButton.icon(
                onPressed: _isDeleting ? null : _handleDelete,
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                label: const Text(
                  'XÓA XE NÀY',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger, fontSize: 15),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.danger, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
