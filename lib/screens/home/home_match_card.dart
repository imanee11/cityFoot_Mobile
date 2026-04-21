import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/supabase_constants.dart';
import '../../models/reservation_model.dart';
import '../../models/produit_model.dart';

class HomeMatchCard extends StatefulWidget {
  final ReservationModel reservation;

  const HomeMatchCard({super.key, required this.reservation});

  @override
  State<HomeMatchCard> createState() => _HomeMatchCardState();
}

class _HomeMatchCardState extends State<HomeMatchCard> {
  ProduitModel? _produit;

  @override
  void initState() {
    super.initState();
    _fetchProduit();
  }

  Future<void> _fetchProduit() async {
    final produitId = widget.reservation.produit;
    if (produitId == null) return;
    try {
      final data = await Supabase.instance.client
          .from(SupabaseConstants.produitTable)
          .select()
          .eq('id', produitId)
          .single();
      if (mounted) {
        setState(() => _produit = ProduitModel.fromJson(data));
      }
    } catch (_) {}
  }

  String _sportEmoji(String? sport) {
    switch (sport?.toLowerCase()) {
      case 'football':
        return '⚽';
      case 'padel':
        return '🎾';
      case 'basket':
      case 'basketball':
        return '🏀';
      default:
        return '🏟️';
    }
  }

  String _formatHour(double h) {
    final hour = h.floor();
    final minutes = ((h - hour) * 60).round();
    return '${hour.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    const months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final c = WColors.of(context);
    final r = widget.reservation;
    final sport = r.sport ?? _produit?.sport ?? 'Sport';
    final produitNom = _produit?.nom ?? r.titre ?? 'Match';
    final prix = _produit?.prixUnitaire;
    final heureStr =
        r.heureDebut != null ? _formatHour(r.heureDebut!) : '--:--';
    final dateStr = _formatDate(r.dateDeResa);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.primaryBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _sportEmoji(sport),
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sport,
                      style: TextStyle(
                        color: c.primaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      produitNom,
                      style: TextStyle(
                        color: c.secondaryText,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    heureStr,
                    style: TextStyle(
                      color: c.primaryText,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: TextStyle(
                      color: c.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (prix != null) ...[
            const SizedBox(height: 12),
            Divider(color: c.borderInput, height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(
                    3,
                    (i) => Container(
                      width: 26,
                      height: 26,
                      margin: EdgeInsets.only(left: i == 0 ? 0 : -8),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.15 + i * 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: c.secondaryBackground, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + i),
                          style: const TextStyle(
                            color: primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  '${prix.toStringAsFixed(0)} MAD',
                  style: const TextStyle(
                    color: primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
