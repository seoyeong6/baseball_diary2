import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadImageToFirebase(
    String sourcePath, {
    int quality = 85,
    int maxWidth = 1080,
    int maxHeight = 1080,
  }) async {
    try {
      Uint8List? compressedData;

      if (kIsWeb) {
        // 웹에서는 XFile에서 직접 데이터를 읽음
        final xFile = XFile(sourcePath);
        compressedData = await xFile.readAsBytes();
      } else {
        // 모바일에서는 flutter_image_compress 사용
        compressedData = await FlutterImageCompress.compressWithFile(
          sourcePath,
          minWidth: maxWidth,
          minHeight: maxHeight,
          quality: quality,
          format: CompressFormat.jpeg,
        );
      }

      if (compressedData == null) {
        debugPrint('Failed to get image data');
        return null;
      }

      // Firebase Storage에 업로드
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('images/$fileName');
      
      final uploadTask = ref.putData(
        compressedData,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image to Firebase: $e');
      return null;
    }
  }

  Future<bool> deleteImageFromFirebase(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting image from Firebase: $e');
      return false;
    }
  }

  Future<File?> compressAndSaveImage(
    String sourcePath, {
    int quality = 85,
    int maxWidth = 1080,
    int maxHeight = 1080,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(path.join(dir.path, 'images'));
      
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final targetPath = path.join(imagesDir.path, fileName);

      final compressedData = await FlutterImageCompress.compressWithFile(
        sourcePath,
        minWidth: maxWidth,
        minHeight: maxHeight,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      if (compressedData != null) {
        final compressedFile = File(targetPath);
        await compressedFile.writeAsBytes(compressedData);
        return compressedFile;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return null;
    }
  }

  Future<Uint8List?> compressImageData(
    String sourcePath, {
    int quality = 85,
    int maxWidth = 1080,
    int maxHeight = 1080,
  }) async {
    try {
      return await FlutterImageCompress.compressWithFile(
        sourcePath,
        minWidth: maxWidth,
        minHeight: maxHeight,
        quality: quality,
        format: CompressFormat.jpeg,
      );
    } catch (e) {
      debugPrint('Error compressing image data: $e');
      return null;
    }
  }

  Future<void> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
  }

  Future<void> clearImageCache() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(path.join(dir.path, 'images'));
      
      if (await imagesDir.exists()) {
        await imagesDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Error clearing image cache: $e');
    }
  }

  Future<int> getCacheSize() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(path.join(dir.path, 'images'));
      
      if (!await imagesDir.exists()) {
        return 0;
      }

      int totalSize = 0;
      await for (final entity in imagesDir.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
      
      return totalSize;
    } catch (e) {
      debugPrint('Error calculating cache size: $e');
      return 0;
    }
  }
}