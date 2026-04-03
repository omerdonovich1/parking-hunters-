import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Full-screen photo viewer opened when tapping the spot thumbnail.
class SpotPhotoViewer extends StatelessWidget {
  final String photoUrl;

  const SpotPhotoViewer({super.key, required this.photoUrl});

  static void show(BuildContext context, String photoUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => SpotPhotoViewer(photoUrl: photoUrl),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Center(
              child: Hero(
                tag: photoUrl,
                child: InteractiveViewer(
                  child: CachedNetworkImage(
                    imageUrl: photoUrl,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                ),
              ),
            ),
            // Close button
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
            // Tap hint
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 0,
              right: 0,
              child: const Center(
                child: Text(
                  'Tap anywhere to close · Pinch to zoom',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact thumbnail shown inside the bottom sheet.
class SpotPhotoThumbnail extends StatelessWidget {
  final String photoUrl;

  const SpotPhotoThumbnail({super.key, required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => SpotPhotoViewer.show(context, photoUrl),
      child: Hero(
        tag: photoUrl,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: photoUrl,
            width: double.infinity,
            height: 160,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              height: 160,
              color: Colors.grey.shade200,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (_, __, ___) => Container(
              height: 160,
              color: Colors.grey.shade100,
              child: const Center(
                child: Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
