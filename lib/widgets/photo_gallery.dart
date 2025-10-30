import 'dart:io';
import 'package:flutter/material.dart';

class PhotoGallery extends StatelessWidget {
  final List<String> photoPaths;
  final Function(int index) onPhotoTap;
  final Function(int index)? onPhotoDelete;

  const PhotoGallery({
    super.key,
    required this.photoPaths,
    required this.onPhotoTap,
    this.onPhotoDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (photoPaths.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          '📸 Fotos Anexadas',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: photoPaths.length,
          itemBuilder: (context, index) {
            return _buildPhotoThumbnail(photoPaths[index], index, context);
          },
        ),
      ],
    );
  }

  Widget _buildPhotoThumbnail(String path, int index, BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => onPhotoTap(index),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(path),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        
        if (onPhotoDelete != null)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => onPhotoDelete!(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }
}