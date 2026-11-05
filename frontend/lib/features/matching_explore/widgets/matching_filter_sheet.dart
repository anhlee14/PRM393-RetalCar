import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';

class MatchingFilterSheet extends StatefulWidget {
  final double budget;
  final bool needDriver;
  final String? vehicleType;
  final double budgetWeight;
  final double distanceWeight;
  final double driverWeight;
  final Function({
    required double budget,
    required bool needDriver,
    required String? vehicleType,
    required double budgetWeight,
    required double distanceWeight,
    required double driverWeight,
  }) onApply;

  const MatchingFilterSheet({
    super.key,
    required this.budget,
    required this.needDriver,
    this.vehicleType,
    required this.budgetWeight,
    required this.distanceWeight,
    required this.driverWeight,
    required this.onApply,
  });

  @override
  State<MatchingFilterSheet> createState() => _MatchingFilterSheetState();
}

class _MatchingFilterSheetState extends State<MatchingFilterSheet> {
  late double _budget;
  late bool _needDriver;
  late String? _vehicleType;
  late double _budgetWeight;
  late double _distanceWeight;
  late double _driverWeight;

  final List<String> _vehicleTypes = ['ALL', 'SUV', 'SEDAN', 'MPV', 'HATCHBACK'];

  @override
  void initState() {
    super.initState();
    _budget = widget.budget;
    _needDriver = widget.needDriver;
    _vehicleType = widget.vehicleType ?? 'ALL';
    _budgetWeight = widget.budgetWeight;
    _distanceWeight = widget.distanceWeight;
    _driverWeight = widget.driverWeight;
  }

  void _resetToDefault() {
    setState(() {
      _budget = 2000000;
      _needDriver = false;
      _vehicleType = 'ALL';
      _budgetWeight = 0.35;
      _distanceWeight = 0.35;
      _driverWeight = 0.30;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Bộ Lọc Matching %',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _resetToDefault,
                  child: const Text(
                    'Mặc định',
                    style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Ngân sách tối đa
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ngân sách dự kiến/ngày',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          CurrencyFormatter.format(_budget),
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: Colors.grey.shade200,
                      thumbColor: AppColors.primary,
                      overlayColor: AppColors.primary.withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      value: _budget,
                      min: 500000,
                      max: 4000000,
                      divisions: 35,
                      onChanged: (val) => setState(() => _budget = val),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Tuỳ chọn kèm tài xế
                  Container(
                    decoration: BoxDecoration(
                      color: _needDriver
                          ? Colors.purple.shade50
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _needDriver ? Colors.purple.shade300 : AppColors.border,
                      ),
                    ),
                    child: SwitchListTile(
                      value: _needDriver,
                      activeThumbColor: Colors.purple,
                      title: const Text(
                        'Thuê xe kèm tài xế riêng',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        _needDriver
                            ? 'Ưu tiên cao xe có hỗ trợ tài xế'
                            : 'Không yêu cầu tài xế riêng',
                        style: TextStyle(
                          fontSize: 12,
                          color: _needDriver ? Colors.purple.shade700 : AppColors.textSecondary,
                        ),
                      ),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _needDriver ? Colors.purple.shade100 : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_pin_circle_rounded,
                          color: _needDriver ? Colors.purple : Colors.grey.shade600,
                        ),
                      ),
                      onChanged: (val) => setState(() => _needDriver = val),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. Phân loại loại xe
                  const Text(
                    'Kiểu dáng xe mong muốn',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _vehicleTypes.map((type) {
                      final isSelected = _vehicleType == type;
                      return ChoiceChip(
                        label: Text(type == 'ALL' ? 'Tất cả loại xe' : type),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: Colors.grey.shade100,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _vehicleType = type);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // 4. Thanh trượt trọng số Matching Engine (Nghiệp vụ 4)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade50, Colors.indigo.shade50],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.insights_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Độ Ưu Tiên Thuật Toán (Matching Weights)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Kéo để điều chỉnh tiêu chí bạn coi trọng nhất:',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 14),

                        // Trọng số Giá
                        _buildWeightSlider(
                          label: 'Ưu tiên Tiết Kiệm Giá Rẻ',
                          value: _budgetWeight,
                          color: Colors.green,
                          onChanged: (val) => setState(() => _budgetWeight = val),
                        ),

                        // Trọng số Khoảng cách gần
                        _buildWeightSlider(
                          label: 'Ưu tiên Khoảng Cách Gần Tôi',
                          value: _distanceWeight,
                          color: Colors.orange,
                          onChanged: (val) => setState(() => _distanceWeight = val),
                        ),

                        // Trọng số Nhu cầu Tài xế
                        _buildWeightSlider(
                          label: 'Ưu tiên Có Tài Xế Phục Vụ',
                          value: _driverWeight,
                          color: Colors.purple,
                          onChanged: (val) => setState(() => _driverWeight = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Nút Áp dụng bộ lọc dưới cùng
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                label: const Text(
                  'ÁP DỤNG & TÍNH ĐIỂM MATCHING',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  widget.onApply(
                    budget: _budget,
                    needDriver: _needDriver,
                    vehicleType: _vehicleType,
                    budgetWeight: _budgetWeight,
                    distanceWeight: _distanceWeight,
                    driverWeight: _driverWeight,
                  );
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightSlider({
    required String label,
    required double value,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text(
              '${(value * 100).toInt()}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: color.withValues(alpha: 0.15),
            thumbColor: color,
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: value,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
