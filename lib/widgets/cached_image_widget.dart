import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CachedImageWidget extends StatelessWidget {
  final String? imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const CachedImageWidget({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath == null || imagePath!.isEmpty) {
      return _buildPlaceholder(context);
    }

    Widget imageWidget;
    
    // 로컬 파일인지 네트워크 URL인지 판단
    if (imagePath!.startsWith('http://') || imagePath!.startsWith('https://')) {
      // 네트워크 이미지 - CachedNetworkImage 사용
      imageWidget = CachedNetworkImage(
        imageUrl: imagePath!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _buildLoadingPlaceholder(),
        errorWidget: (context, url, error) => _buildErrorPlaceholder(context),
        memCacheWidth: width != null && width!.isFinite ? width!.toInt() : null,
        memCacheHeight: height != null && height!.isFinite ? height!.toInt() : null,
      );
    } else {
      // 로컬 파일 - Image.file 사용
      final file = File(imagePath!);
      if (!file.existsSync()) {
        return _buildErrorPlaceholder(context);
      }
      
      imageWidget = Image.file(
        file,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(context),
      );
    }

    // BorderRadius 적용
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: borderRadius,
      ),
      child: Icon(
        Icons.image,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        size: 40,
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildErrorPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: borderRadius,
      ),
      child: Icon(
        Icons.broken_image,
        color: theme.colorScheme.onErrorContainer.withValues(alpha: 0.7),
        size: 40,
      ),
    );
  }
}