import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/file_upload_service.dart';
import '../../vehicle_management/screens/owner_vehicle_list_screen.dart';
import '../../vehicle_management/screens/admin_vehicle_approval_screen.dart';
import '../../booking/screens/booking_history_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final user = await AuthService.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _user = user;
      _isLoading = false;
    });
  }

  void _changeAvatar() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Cập nhật ảnh đại diện',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: const Text('Chụp ảnh mới'),
                onTap: () {
                  Navigator.pop(ctx);
                  _uploadAndSaveAvatar(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('Chọn ảnh từ thư viện'),
                onTap: () {
                  Navigator.pop(ctx);
                  _uploadAndSaveAvatar(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadAndSaveAvatar(ImageSource source) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 12),
            Text('Đang tải ảnh...'),
          ],
        ),
        duration: Duration(seconds: 10),
      ),
    );

    final res = await FileUploadService.pickAndUpload(source: source, folder: 'avatars');
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (res['success'] == true) {
      final newUrl = res['url'];
      final updateRes = await AuthService.updateProfile(avatarUrl: newUrl);
      if (!mounted) return;

      if (updateRes['success'] == true) {
        _loadProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật ảnh đại diện thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(updateRes['message'] ?? 'Cập nhật ảnh thất bại'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } else if (res['message'] != 'Đã hủy chọn ảnh') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Tải ảnh thất bại'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _showEditProfileSheet() {
    if (_user == null) return;

    final nameController = TextEditingController(text: _user!.fullName);
    final phoneController = TextEditingController(text: _user!.phone);
    final cccdController = TextEditingController(text: _user!.cccdNumber ?? '');
    final licenseController = TextEditingController(text: _user!.driverLicense ?? '');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Chỉnh Sửa Hồ Sơ Cá Nhân',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 10),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cccdController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Số CCCD / CMND',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.credit_card),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: licenseController,
                  decoration: const InputDecoration(
                    labelText: 'Giấy phép lái xe (GPLX)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.card_membership),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(ctx);
                          setSheetState(() => isSaving = true);
                          final res = await AuthService.updateProfile(
                            fullName: nameController.text.trim(),
                            phone: phoneController.text.trim(),
                            cccdNumber: cccdController.text.trim().isEmpty ? null : cccdController.text.trim(),
                            driverLicense: licenseController.text.trim().isEmpty ? null : licenseController.text.trim(),
                          );

                          if (!mounted) return;
                          setSheetState(() => isSaving = false);

                          if (res['success'] == true) {
                            nav.pop();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Cập nhật hồ sơ thành công!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            _loadProfile();
                          } else {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(res['message'] ?? 'Lỗi khi cập nhật'),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'LƯU THAY ĐỔI',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ApiClient.clearToken();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (ctx) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hồ Sơ Cá Nhân')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hồ Sơ Cá Nhân')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off, size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Bạn chưa đăng nhập hoặc phiên làm việc đã hết hạn'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (ctx) => const LoginScreen()),
                  ).then((_) => _loadProfile());
                },
                icon: const Icon(Icons.login),
                label: const Text('Đăng nhập ngay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ Sơ Cá Nhân'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Sửa thông tin',
            onPressed: _showEditProfileSheet,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar & Basic Info Card
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: AppColors.primary.withAlpha(40),
                    child: (_user!.avatarUrl != null && _user!.avatarUrl!.isNotEmpty)
                        ? ClipOval(
                            child: Image.network(
                              ApiEndpoints.resolveImageUrl(_user!.avatarUrl!),
                              width: 92,
                              height: 92,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) =>
                                  const Icon(Icons.person, size: 54, color: AppColors.primary),
                            ),
                          )
                        : const Icon(Icons.person, size: 54, color: AppColors.primary),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _changeAvatar,
                      child: const CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primary,
                        child: Icon(Icons.camera_alt, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _user!.fullName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _user!.email,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'SĐT: ${_user!.phone.isEmpty ? 'Chưa cập nhật' : _user!.phone}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Mục Quản lý xe cho thuê của tôi (Chức năng Thành viên 1)
                        if (_user?.role == 'ROLE_ADMIN') ...[
              Card(
                elevation: 3,
                color: const Color(0xFFF0FDF4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Colors.green, width: 1.5),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.green,
                    child: Icon(Icons.admin_panel_settings, color: Colors.white),
                  ),
                  title: const Row(
                    children: [
                      Text(
                        'Quản trị duyệt xe (Admin)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                      ),
                      SizedBox(width: 8),
                      Badge(
                        label: Text('ADMIN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        backgroundColor: Colors.redAccent,
                      ),
                    ],
                  ),
                  subtitle: const Text(
                    'Xem toàn bộ xe đang chờ duyệt trên hệ thống, phê duyệt hoặc từ chối',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.green),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (ctx) => const AdminVehicleApprovalScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: AppColors.primary.withAlpha(80), width: 1.2),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: const CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.directions_car, color: Colors.white),
                ),
                title: const Text(
                  'Quản lý xe cho thuê của tôi',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: const Text(
                  'Xem danh sách xe của bạn, đăng xe mới & theo dõi duyệt xe',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primary),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (ctx) => const OwnerVehicleListScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Mục Duyệt đơn thuê xe của khách (Chức năng Chủ xe)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: AppColors.success.withAlpha(80), width: 1.2),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: const CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.success,
                  child: Icon(Icons.assignment_turned_in, color: Colors.white),
                ),
                title: const Text(
                  'Duyệt đơn thuê xe của khách',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: const Text(
                  'Xem các yêu cầu đặt xe từ khách thuê & bấm Duyệt đơn',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.success),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (ctx) => const BookingHistoryScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Identity Cards
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.badge, color: Colors.green),
                ),
                title: const Text('Số Căn cước công dân (CCCD)', style: TextStyle(fontSize: 13, color: Colors.grey)),
                subtitle: Text(
                  (_user!.cccdNumber != null && _user!.cccdNumber!.isNotEmpty)
                      ? _user!.cccdNumber!
                      : 'Chưa cập nhật',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: _showEditProfileSheet,
                ),
              ),
            ),
            const SizedBox(height: 10),

            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFF3E0),
                  child: Icon(Icons.drive_eta, color: Colors.orange),
                ),
                title: const Text('Giấy phép lái xe (GPLX)', style: TextStyle(fontSize: 13, color: Colors.grey)),
                subtitle: Text(
                  (_user!.driverLicense != null && _user!.driverLicense!.isNotEmpty)
                      ? _user!.driverLicense!
                      : 'Chưa cập nhật',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: _showEditProfileSheet,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Edit Profile Button
            OutlinedButton.icon(
              onPressed: _showEditProfileSheet,
              icon: const Icon(Icons.person_pin),
              label: const Text('CHỈNH SỬA THÔNG TIN CÁ NHÂN'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),

            // Logout Button
            ElevatedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout),
              label: const Text('ĐĂNG XUẤT'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.red.shade200),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
