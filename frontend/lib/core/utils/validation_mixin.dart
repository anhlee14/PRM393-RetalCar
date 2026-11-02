mixin ValidationMixin {
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập họ và tên';
    }
    if (value.trim().length < 2) {
      return 'Họ và tên quá ngắn';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email không đúng định dạng';
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }
    final phoneRegex = RegExp(r'^(0|\+84)[0-9]{9}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Số điện thoại phải gồm 10 chữ số hợp lệ';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.trim().length < 6) {
      return 'Mật khẩu phải từ 6 ký tự trở lên';
    }
    return null;
  }

  String? validateCccd(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Không bắt buộc
    if (value.trim().length != 12) {
      return 'Số CCCD phải gồm 12 chữ số';
    }
    return null;
  }
}

