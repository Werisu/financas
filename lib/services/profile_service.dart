import 'dart:convert';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class ProfilePhotoData {
  const ProfilePhotoData({
    required this.bytes,
    required this.base64,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String base64;
  final String mimeType;

  String get dataUrl => 'data:$mimeType;base64,$base64';
}

class ProfileService {
  ProfileService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Compacta forte para caber no Firestore (limite de 1 MB por documento).
  Future<ProfilePhotoData?> pickCompressedProfileImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 320,
      maxHeight: 320,
      imageQuality: 55,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    if (bytes.lengthInBytes > 700 * 1024) {
      throw StateError(
        'A imagem ficou grande demais. Escolha outra foto mais leve.',
      );
    }

    final mimeType = file.mimeType ?? 'image/jpeg';
    return ProfilePhotoData(
      bytes: bytes,
      base64: base64Encode(bytes),
      mimeType: mimeType,
    );
  }

  static Uint8List? decodeBase64Photo(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      final raw = value.contains(',') ? value.split(',').last : value;
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }
}
