import 'dart:io';
import 'package:flutter/material.dart';
import 'package:buta_app/shared/models/models.dart';

class AvatarCard extends StatelessWidget {
  final Avatar? avatar;
  final String? imagePath;

  const AvatarCard({super.key, this.avatar, this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // アバター画像
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 120,
                height: 120,
                child: _buildImage(),
              ),
            ),
            const SizedBox(height: 12),
            // 名前
            Text(
              avatar?.name ?? 'ぶたさん',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            // レベル
            Text(
              'Lv.${avatar?.level ?? 1}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFFFF69B4),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (imagePath != null && File(imagePath!).existsSync()) {
      return Image.file(File(imagePath!), fit: BoxFit.cover);
    }
    // プレースホルダー
    return Container(
      color: const Color(0xFFFFF0F5),
      child: const Icon(Icons.pets, size: 60, color: Color(0xFFFF69B4)),
    );
  }
}
