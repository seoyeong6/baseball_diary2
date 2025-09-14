import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Connectivity _connectivity = Connectivity();

  // Upload queue management
  static const String _uploadQueueKey = 'image_upload_queue';
  static const String _uploadMetadataKey = 'image_upload_metadata';

  Timer? _retryTimer;
  bool _isProcessingQueue = false;
  int _retryCount = 0;
  static const int _maxRetries = 5;

  /// Offline-first image upload with automatic retry
  Future<ImageUploadResult> uploadImageOfflineFirst(
    String sourcePath, {
    required String entryId,
    int quality = 85,
    int maxWidth = 1080,
    int maxHeight = 1080,
  }) async {
    try {
      // Step 1: Save image locally first
      final localFile = await compressAndSaveImage(
        sourcePath,
        quality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      if (localFile == null) {
        return ImageUploadResult(
          success: false,
          error: 'Failed to save image locally',
        );
      }

      // Step 2: Check network connectivity
      final isOnline = await _isOnline();

      if (!isOnline) {
        // Add to upload queue for later processing
        await _addToUploadQueue(
          entryId: entryId,
          localPath: localFile.path,
          originalPath: sourcePath,
        );

        return ImageUploadResult(
          success: true,
          localPath: localFile.path,
          uploadPending: true,
        );
      }

      // Step 3: Try to upload immediately if online
      final remoteUrl = await _uploadToFirebase(
        localFile.path,
        quality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      if (remoteUrl != null) {
        return ImageUploadResult(
          success: true,
          localPath: localFile.path,
          remoteUrl: remoteUrl,
          uploadPending: false,
        );
      } else {
        // Upload failed, add to queue
        await _addToUploadQueue(
          entryId: entryId,
          localPath: localFile.path,
          originalPath: sourcePath,
        );

        return ImageUploadResult(
          success: true,
          localPath: localFile.path,
          uploadPending: true,
        );
      }
    } catch (e) {
      return ImageUploadResult(
        success: false,
        error: 'Upload failed: $e',
      );
    }
  }

  /// Legacy method for backward compatibility
  Future<String?> uploadImageToFirebase(
    String sourcePath, {
    int quality = 85,
    int maxWidth = 1080,
    int maxHeight = 1080,
  }) async {
    return await _uploadToFirebase(
      sourcePath,
      quality: quality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }

  /// Internal method to upload to Firebase
  Future<String?> _uploadToFirebase(
    String sourcePath, {
    int quality = 85,
    int maxWidth = 1080,
    int maxHeight = 1080,
  }) async {
    try {
      Uint8List? compressedData;

      if (kIsWeb) {
        // 웹에서는 파일에서 직접 데이터를 읽음
        final file = File(sourcePath);
        compressedData = await file.readAsBytes();
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
      if (kDebugMode) {
        print('Firebase upload error: $e');
      }
      return null;
    }
  }

  Future<bool> deleteImageFromFirebase(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
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
      return 0;
    }
  }

  // ========== Offline Queue Management ==========

  /// Check network connectivity
  Future<bool> _isOnline() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return !connectivityResult.contains(ConnectivityResult.none);
    } catch (e) {
      // Assume online if connectivity check fails
      return true;
    }
  }

  /// Add image to upload queue
  Future<void> _addToUploadQueue({
    required String entryId,
    required String localPath,
    required String originalPath,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing queue
      final queueJson = prefs.getString(_uploadQueueKey);
      final List<dynamic> queue = queueJson != null
          ? json.decode(queueJson) as List<dynamic>
          : [];

      // Add new item
      queue.add({
        'entryId': entryId,
        'localPath': localPath,
        'originalPath': originalPath,
        'addedAt': DateTime.now().toIso8601String(),
        'retryCount': 0,
      });

      // Save updated queue
      await prefs.setString(_uploadQueueKey, json.encode(queue));

      // Start processing queue if not already running
      _startQueueProcessor();
    } catch (e) {
      if (kDebugMode) {
        print('Error adding to upload queue: $e');
      }
    }
  }

  /// Get pending uploads
  Future<List<Map<String, dynamic>>> getPendingUploads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_uploadQueueKey);

      if (queueJson == null) {
        return [];
      }

      final List<dynamic> queue = json.decode(queueJson) as List<dynamic>;
      return queue.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Start processing upload queue
  void _startQueueProcessor() {
    if (_isProcessingQueue) return;

    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(
      Duration(seconds: _getRetryDelay()),
      (_) => processUploadQueue(),
    );

    // Process immediately
    processUploadQueue();
  }

  /// Get retry delay with exponential backoff
  int _getRetryDelay() {
    // Exponential backoff: 5s, 10s, 20s, 40s, 80s
    return 5 * (1 << _retryCount.clamp(0, 4));
  }

  /// Process pending uploads
  Future<void> processUploadQueue() async {
    if (_isProcessingQueue) return;

    _isProcessingQueue = true;

    try {
      // Check if online
      if (!await _isOnline()) {
        _isProcessingQueue = false;
        return;
      }

      // Get pending uploads
      final queue = await getPendingUploads();
      if (queue.isEmpty) {
        _retryTimer?.cancel();
        _isProcessingQueue = false;
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final updatedQueue = <Map<String, dynamic>>[];
      bool anySuccess = false;

      for (final item in queue) {
        final entryId = item['entryId'] as String;
        final localPath = item['localPath'] as String;
        int retryCount = item['retryCount'] as int? ?? 0;

        // Check if file still exists
        final file = File(localPath);
        if (!await file.exists()) {
          continue; // Skip this item
        }

        // Try to upload
        final remoteUrl = await _uploadToFirebase(localPath);

        if (remoteUrl != null) {
          // Upload successful
          anySuccess = true;

          // Notify about successful upload (you might want to implement a callback here)
          await _onUploadSuccess(entryId, localPath, remoteUrl);
        } else {
          // Upload failed
          retryCount++;

          if (retryCount < _maxRetries) {
            // Keep in queue for retry
            updatedQueue.add({
              ...item,
              'retryCount': retryCount,
            });
          } else {
            // Max retries reached, remove from queue
            await _onUploadFailed(entryId, localPath);
          }
        }
      }

      // Update queue
      if (updatedQueue.isEmpty) {
        await prefs.remove(_uploadQueueKey);
        _retryTimer?.cancel();
      } else {
        await prefs.setString(_uploadQueueKey, json.encode(updatedQueue));
      }

      // Reset retry count on any success
      if (anySuccess) {
        _retryCount = 0;
      } else {
        _retryCount++;
      }

    } catch (e) {
      if (kDebugMode) {
        print('Error processing upload queue: $e');
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  /// Handle successful upload
  Future<void> _onUploadSuccess(String entryId, String localPath, String remoteUrl) async {
    // Store metadata about successful upload
    final prefs = await SharedPreferences.getInstance();
    final metadataJson = prefs.getString(_uploadMetadataKey);
    final Map<String, dynamic> metadata = metadataJson != null
        ? json.decode(metadataJson) as Map<String, dynamic>
        : {};

    metadata[entryId] = {
      'localPath': localPath,
      'remoteUrl': remoteUrl,
      'uploadedAt': DateTime.now().toIso8601String(),
    };

    await prefs.setString(_uploadMetadataKey, json.encode(metadata));

    // You might want to trigger a callback or notification here
    // to update the diary entry with the remote URL
  }

  /// Handle failed upload after max retries
  Future<void> _onUploadFailed(String entryId, String localPath) async {
    if (kDebugMode) {
      print('Upload failed for entry $entryId after max retries');
    }
    // You might want to notify the user or log this failure
  }

  /// Get upload metadata for an entry
  Future<Map<String, dynamic>?> getUploadMetadata(String entryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metadataJson = prefs.getString(_uploadMetadataKey);

      if (metadataJson == null) return null;

      final metadata = json.decode(metadataJson) as Map<String, dynamic>;
      return metadata[entryId] as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  /// Clear upload queue (for debugging/maintenance)
  Future<void> clearUploadQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_uploadQueueKey);
    await prefs.remove(_uploadMetadataKey);
    _retryTimer?.cancel();
    _retryCount = 0;
  }

  /// Initialize upload queue processor on app start
  void initializeQueueProcessor() {
    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (!results.contains(ConnectivityResult.none)) {
        // Back online, process queue
        processUploadQueue();
      }
    });

    // Process any pending uploads on start
    processUploadQueue();
  }
}

/// Result class for image upload operations
class ImageUploadResult {
  final bool success;
  final String? localPath;
  final String? remoteUrl;
  final bool uploadPending;
  final String? error;

  ImageUploadResult({
    required this.success,
    this.localPath,
    this.remoteUrl,
    this.uploadPending = false,
    this.error,
  });
}