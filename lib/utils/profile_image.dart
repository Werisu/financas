import 'dart:typed_data';

import 'package:financas/services/profile_service.dart';
import 'package:flutter/material.dart';

ImageProvider? profileImageProvider({
  String? photoBase64,
  String? photoUrl,
  Uint8List? localBytes,
}) {
  if (localBytes != null) return MemoryImage(localBytes);
  final decoded = ProfileService.decodeBase64Photo(photoBase64);
  if (decoded != null) return MemoryImage(decoded);
  if (photoUrl != null && photoUrl.isNotEmpty) return NetworkImage(photoUrl);
  return null;
}
