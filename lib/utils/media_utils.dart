import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Local path လား Network URL လား auto-detect ပြီး display
Widget buildMediaImage(
    String path, {
      double? width,
      double? height,
      BoxFit fit = BoxFit.cover,
    }) {
  final placeholder = Container(
    width: width, height: height ?? 80,
    color: AppColors.primarySurface,
    child: Icon(Icons.image_outlined,
        color: AppColors.primaryLight.withOpacity(0.4),
        size: ((height ?? 80) * 0.35).clamp(16, 36)),
  );

  final isNetwork = path.startsWith('http://') || path.startsWith('https://');

  if (isNetwork) {
    return Image.network(
      path, width: width, height: height, fit: fit,
      loadingBuilder: (_, child, prog) => prog == null ? child : placeholder,
      errorBuilder: (_, __, ___) => Container(
        width: width, height: height,
        color: AppColors.primarySurface,
        child: const Icon(Icons.broken_image_outlined, color: AppColors.textHint),
      ),
    );
  }

  return Image.file(
    File(path), width: width, height: height, fit: fit,
    errorBuilder: (_, __, ___) => placeholder,
  );
}

bool isNetworkUrl(String path) =>
    path.startsWith('http://') || path.startsWith('https://');