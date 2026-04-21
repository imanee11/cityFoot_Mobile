import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/terrain_model.dart';
import '../../widgets/custom_button.dart';
import '../match/reserver_screen.dart';

class TerrainDetailScreen extends StatelessWidget {
  final TerrainModel terrain;

  const TerrainDetailScreen({super.key, required this.terrain});

  @override
  Widget build(BuildContext context) {
    final c = WColors.of(context);
    return Scaffold(
      backgroundColor: c.primaryBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: c.primaryBackground,
            iconTheme: IconThemeData(color: c.primaryText),
            flexibleSpace: FlexibleSpaceBar(
              background: terrain.img != null && terrain.img!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: terrain.img!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: c.secondaryBackground),
                      errorWidget: (context, url, error) => Container(
                        color: c.secondaryBackground,
                        child: Icon(Icons.sports_soccer,
                            color: c.secondaryText, size: 60),
                      ),
                    )
                  : Container(
                      color: c.secondaryBackground,
                      child: Icon(Icons.sports_soccer,
                          color: c.secondaryText, size: 60),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    terrain.nom ?? 'Terrain',
                    style: TextStyle(
                      color: c.primaryText,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _infoRow(Icons.location_on_outlined,
                      terrain.adresse ?? 'Adresse non disponible', c),
                  const SizedBox(height: 8),
                  _infoRow(Icons.sports_soccer, terrain.sport ?? '', c),
                  const SizedBox(height: 8),
                  _infoRow(
                    Icons.attach_money,
                    terrain.prix != null
                        ? '${terrain.prix!.toStringAsFixed(0)} DH/heure'
                        : 'Prix non disponible',
                    c,
                  ),
                  if (terrain.description != null &&
                      terrain.description!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Description',
                      style: TextStyle(
                        color: c.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      terrain.description!,
                      style: TextStyle(
                          color: c.secondaryText, fontSize: 14, height: 1.5),
                    ),
                  ],
                  const SizedBox(height: 40),
                  CustomButton(
                    label: 'Réserver',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReserverScreen(terrain: terrain),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, WColors c) {
    return Row(
      children: [
        Icon(icon, color: primary, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: c.secondaryText, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
