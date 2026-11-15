import 'dart:typed_data';

import 'package:flutter/material.dart';

class BookCover extends StatelessWidget {
  final dynamic source;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;

  const BookCover({
    super.key,
    required this.source,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: _buildImage(context),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final fallback = Image.asset(
      'assets/images/cover.png',
      width: width,
      height: height,
      fit: fit,
    );

    if (source is Uint8List) {
      return Image.memory(
        source,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    if (source is String && source.trim().isNotEmpty) {
      final path = source.trim();
      if (path.startsWith('http')) {
        return Image.network(
          path,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => fallback,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: width,
              height: height,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
        );
      }
      return Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    return fallback;
  }
}
