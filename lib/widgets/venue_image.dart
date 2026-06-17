import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class VenueImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const VenueImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final image = imageUrl.trim();

    if (image.isEmpty) {
      return _ImageFallback(
        width: width,
        height: height,
        icon: Icons.image_not_supported_outlined,
        text: 'Gambar kosong',
      );
    }

    if (image.startsWith('http://') || image.startsWith('https://')) {
      return Image.network(
        image,
        width: width,
        height: height,
        fit: fit,

        // Penting untuk Flutter Web agar beberapa URL gambar tetap bisa tampil.
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,

        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;

          return Container(
            width: width,
            height: height,
            color: AppColors.primary,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AppColors.accent,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('GAGAL LOAD IMAGE URL: $image');
          debugPrint('IMAGE ERROR: $error');

          return _ImageFallback(
            width: width,
            height: height,
            icon: Icons.broken_image_outlined,
            text: 'Gambar gagal dimuat',
          );
        },
      );
    }

    return Image.asset(
      image,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('GAGAL LOAD ASSET IMAGE: $image');
        debugPrint('ASSET ERROR: $error');

        return _ImageFallback(
          width: width,
          height: height,
          icon: Icons.broken_image_outlined,
          text: 'Asset gagal dimuat',
        );
      },
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final double? width;
  final double? height;
  final IconData icon;
  final String text;

  const _ImageFallback({
    required this.width,
    required this.height,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppColors.primary,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: AppColors.accent,
            size: 42,
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
