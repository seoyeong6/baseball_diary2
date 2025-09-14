import 'package:flutter/material.dart';
import '../models/diary_entry.dart';
import '../services/image_service.dart';

/// Widget to display image upload status
class ImageUploadIndicator extends StatefulWidget {
  final DiaryEntry entry;
  final VoidCallback? onUploadComplete;

  const ImageUploadIndicator({
    super.key,
    required this.entry,
    this.onUploadComplete,
  });

  @override
  State<ImageUploadIndicator> createState() => _ImageUploadIndicatorState();
}

class _ImageUploadIndicatorState extends State<ImageUploadIndicator> {
  final ImageService _imageService = ImageService();
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkUploadStatus();
  }

  Future<void> _checkUploadStatus() async {
    if (!widget.entry.imageUploadPending! || _isChecking) return;

    setState(() {
      _isChecking = true;
    });

    try {
      // Check if upload has completed
      final metadata = await _imageService.getUploadMetadata(widget.entry.id);
      if (metadata != null && metadata['remoteUrl'] != null) {
        // Upload completed
        widget.onUploadComplete?.call();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }

    // Check again in a few seconds
    if (mounted && widget.entry.imageUploadPending!) {
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          _checkUploadStatus();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.entry.hasImage) {
      return const SizedBox.shrink();
    }

    if (widget.entry.imageUploadPending != true) {
      // Upload complete or not needed
      return const SizedBox.shrink();
    }

    // Show upload pending indicator
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isChecking)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            )
          else
            const Icon(
              Icons.cloud_upload_outlined,
              size: 16,
              color: Colors.orange,
            ),
          const SizedBox(width: 6),
          Text(
            _isChecking ? '업로드 확인 중...' : '업로드 대기 중',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple icon indicator for upload status
class ImageUploadStatusIcon extends StatelessWidget {
  final bool? uploadPending;
  final double size;

  const ImageUploadStatusIcon({
    super.key,
    required this.uploadPending,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (uploadPending != true) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.9),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.cloud_upload,
        size: size,
        color: Colors.white,
      ),
    );
  }
}