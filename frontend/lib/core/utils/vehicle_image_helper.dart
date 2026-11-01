import '../../data/models/vehicle_model.dart';

class VehicleImageHelper {
  // Ảnh chuẩn 100% đúng dòng xe, chất lượng cao
  static const String vf8Front =
      'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/2022_Vinfast_VF8_front_view.jpg/1280px-2022_Vinfast_VF8_front_view.jpg';
  static const String vf8Side =
      'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1b/VinFast_VF_8_DSC_8470.jpg/1280px-VinFast_VF_8_DSC_8470.jpg';
  static const String vf8Interior =
      'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Interior_of_VinFast_VF8_car.jpg/1280px-Interior_of_VinFast_VF8_car.jpg';

  static const String viosFront =
      'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0e/Toyota_Vios_1.5_G_2019_%282%29.jpg/1280px-Toyota_Vios_1.5_G_2019_%282%29.jpg';
  static const String viosSide =
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Third_generation_Toyota_Vios-1-.jpg/1280px-Third_generation_Toyota_Vios-1-.jpg';
  static const String viosInterior =
      'https://images.unsplash.com/photo-1552519507-da3b142c6e3d';

  static const String tucsonFront =
      'https://upload.wikimedia.org/wikipedia/commons/thumb/5/56/Hyundai_Tucson_%28NX4%2C_SWB%29_Facelift_IMG_2344.jpg/1280px-Hyundai_Tucson_%28NX4%2C_SWB%29_Facelift_IMG_2344.jpg';
  static const String tucsonSide =
      'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f9/Hyundai_Tucson_%28NX4%29_PHEV_IMG_4375.jpg/1280px-Hyundai_Tucson_%28NX4%29_PHEV_IMG_4375.jpg';
  static const String tucsonInterior =
      'https://images.unsplash.com/photo-1542282088-72c9c27ed0cd';

  static const String xpanderFront =
      'https://upload.wikimedia.org/wikipedia/commons/thumb/3/38/Mitsubishi_Xpander_Sport_%28depan%29%2C_Palangkaraya.jpg/1280px-Mitsubishi_Xpander_Sport_%28depan%29%2C_Palangkaraya.jpg';
  static const String xpanderSide =
      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cf/Mitsubishi_Xpander_1.5_GLX_Plus_2019.jpg/1280px-Mitsubishi_Xpander_1.5_GLX_Plus_2019.jpg';
  static const String xpanderInterior =
      'https://images.unsplash.com/photo-1503376780353-7e6692767b70';

  // Lấy ảnh đại diện chính xác tuyệt đối theo tên và hãng xe
  static String getThumbnail(VehicleModel vehicle) {
    final name = vehicle.name.toLowerCase();
    final brand = vehicle.brand.toLowerCase();
    final url = vehicle.thumbnailUrl?.trim() ?? '';

    // Nếu ảnh trong DB là link upload local bị 404 hoặc link unsplash ngẫu nhiên bị sai dòng xe
    final isBrokenLocal = url.contains('localhost:8080/uploads');
    final isMismatchedUnsplash = url.contains('photo-1549399542-7e3f8b79c341') ||
        url.contains('photo-1580273916550-e323be2ae537') ||
        url.contains('photo-1533473359331-0135ef1b58bf');

    if (url.isEmpty || isBrokenLocal || isMismatchedUnsplash) {
      return _matchAccurateImage(name, brand, vehicle.vehicleType);
    }

    return url;
  }

  // Danh sách các góc ảnh thực tế của xe phục vụ màn hình chi tiết (Carousel)
  static List<String> getGalleryImages(VehicleModel vehicle) {
    final name = vehicle.name.toLowerCase();
    final brand = vehicle.brand.toLowerCase();

    if (name.contains('vf8') || name.contains('vf 8') || brand.contains('vinfast')) {
      return [vf8Front, vf8Side, vf8Interior];
    }
    if (name.contains('vios') || brand.contains('toyota')) {
      return [viosFront, viosSide, viosInterior];
    }
    if (name.contains('tucson') || name.contains('santafe') || brand.contains('hyundai')) {
      return [tucsonFront, tucsonSide, tucsonInterior];
    }
    if (name.contains('xpander') || brand.contains('mitsubishi')) {
      return [xpanderFront, xpanderSide, xpanderInterior];
    }

    final thumb = getThumbnail(vehicle);
    return [thumb];
  }

  static String _matchAccurateImage(String name, String brand, String type) {
    // 1. VinFast VF8 / VF9 / Xe điện VinFast
    if (name.contains('vf8') || name.contains('vf 8') || name.contains('vf9') || brand.contains('vinfast')) {
      return vf8Front;
    }

    // 2. Toyota Vios
    if (name.contains('vios') || (brand.contains('toyota') && type.toUpperCase() == 'SEDAN')) {
      return viosFront;
    }

    // 3. Hyundai Tucson
    if (name.contains('tucson') || (brand.contains('hyundai') && type.toUpperCase() == 'SUV')) {
      return tucsonFront;
    }

    // 4. Mitsubishi Xpander / MPV 7 chỗ
    if (name.contains('xpander') || type.toUpperCase() == 'MPV') {
      return xpanderFront;
    }

    // Theo loại xe chung (Fallback)
    switch (type.toUpperCase()) {
      case 'SUV':
        return tucsonFront;
      case 'SEDAN':
        return viosFront;
      case 'MPV':
        return xpanderFront;
      default:
        return vf8Front;
    }
  }
}
