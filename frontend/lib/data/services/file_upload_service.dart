import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';

class FileUploadService {
  static final ImagePicker _picker = ImagePicker();

  /// Chọn ảnh từ máy và tải lên qua Backend (Cloudinary hoặc Local Fallback)
  /// [source]: ImageSource.gallery hoặc ImageSource.camera
  /// [folder]: 'vehicles', 'avatars', 'inspections'
  static Future<Map<String, dynamic>> pickAndUpload({
    required ImageSource source,
    String folder = 'vehicles',
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return {'success': false, 'message': 'Đã hủy chọn ảnh'};
      }

      return await uploadXFile(pickedFile, folder: folder);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi chọn ảnh: $e'};
    }
  }

  /// Chọn nhiều ảnh từ thư viện và tải lên (tối đa maxImages)
  /// Trả về Map: `{'success': bool, 'urls': List<String>, 'message': String}`
  static Future<Map<String, dynamic>> pickMultiAndUpload({
    int maxImages = 6,
    String folder = 'vehicles',
    Function(int current, int total)? onProgress,
  }) async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFiles.isEmpty) {
        return {
          'success': false,
          'urls': <String>[],
          'message': 'Đã hủy chọn ảnh',
        };
      }

      final filesToUpload = pickedFiles.take(maxImages).toList();
      List<String> uploadedUrls = [];
      String? lastError;

      for (int i = 0; i < filesToUpload.length; i++) {
        if (onProgress != null) onProgress(i + 1, filesToUpload.length);
        final res = await uploadXFile(filesToUpload[i], folder: folder);
        if (res['success'] == true && res['url'] != null) {
          uploadedUrls.add(res['url'] as String);
        } else {
          lastError = res['message'] as String?;
        }
      }

      if (uploadedUrls.isEmpty && lastError != null) {
        return {
          'success': false,
          'urls': <String>[],
          'message': lastError,
        };
      }

      return {
        'success': true,
        'urls': uploadedUrls,
        'message': uploadedUrls.length == filesToUpload.length
            ? 'Đã tải lên ${uploadedUrls.length} ảnh thành công'
            : 'Đã tải ${uploadedUrls.length}/${filesToUpload.length} ảnh (${lastError ?? "Một số ảnh lỗi"})',
      };
    } catch (e) {
      return {
        'success': false,
        'urls': <String>[],
        'message': 'Lỗi chọn ảnh: $e',
      };
    }
  }

  /// Tải một XFile trực tiếp lên Backend
  static Future<Map<String, dynamic>> uploadXFile(
    XFile xFile, {
    String folder = 'vehicles',
  }) async {
    try {
      final uri = Uri.parse(ApiEndpoints.uploadFile);
      final request = http.MultipartRequest('POST', uri);

      // Thêm token nếu có
      final token = await ApiClient.getToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Thêm tham số folder
      request.fields['folder'] = folder;

      // Đọc bytes tương thích 100% cả Android, iOS và Web
      final bytes = await xFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: xFile.name.isNotEmpty ? xFile.name : 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && data['success'] == true) {
        final fileUrl = data['data']['file_url'] as String;
        return {
          'success': true,
          'url': fileUrl,
          'message': 'Tải ảnh lên thành công',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Lỗi tải ảnh lên máy chủ (${response.statusCode})',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối máy chủ khi tải ảnh: $e'};
    }
  }
}
