import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/terrain_model.dart';

class TerrainCard extends StatelessWidget {
  final TerrainModel terrain;
  final VoidCallback onTap;

  const TerrainCard({super.key, required this.terrain, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = WColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: c.secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: terrain.img != null && terrain.img!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: terrain.img!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 160,
                        color: c.primaryBackground,
                        child: const Center(
                          child: CircularProgressIndicator(color: primary),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 160,
                        color: c.primaryBackground,
                        child: Icon(Icons.sports_soccer,
                            color: c.secondaryText, size: 48),
                      ),
                    )
                  : Container(
                      height: 160,
                      color: c.primaryBackground,
                      child: Center(
                        child: Icon(Icons.sports_soccer,
                            color: c.secondaryText, size: 48),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    terrain.nom ?? 'Terrain',
                    style: TextStyle(
                      color: c.primaryText,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          color: c.secondaryText, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          terrain.adresse ?? '',
                          style: TextStyle(
                              color: c.secondaryText, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          terrain.sport ?? '',
                          style: const TextStyle(
                              color: primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        terrain.prix != null
                            ? '${terrain.prix!.toStringAsFixed(0)} DH/h'
                            : '',
                        style: const TextStyle(
                          color: primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
