import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Pilih foto dari galeri/kamera. Plugin sudah mengecilkan sisi terpanjang
/// ke [maxSide] px dan mengompres JPEG ke ~80%, jadi yang diunggah bukan
/// file asli kamera (biasanya 3-8 MB).
Future<XFile?> pilihFoto(BuildContext context, {required double maxSide}) async {
  final sumber = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Pilih dari galeri'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Ambil dengan kamera'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
        ],
      ),
    ),
  );
  if (sumber == null) return null;
  return ImagePicker().pickImage(
    source: sumber,
    maxWidth: maxSide,
    maxHeight: maxSide,
    imageQuality: 80,
    requestFullMetadata: false,
  );
}
