import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/supabase_constants.dart';
import '../../models/reservation_model.dart';
import 'package:intl/intl.dart';

class MatchCard extends StatefulWidget {
  final ReservationModel reservation;

  const MatchCard({super.key, required this.reservation});

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard> {
  String? _terrainName;

  @override
  void initState() {
    super.initState();
    _fetchTerrain();
  }

  Future<void> _fetchTerrain() async {
    if (widget.reservation.terrain == null) return;
    try {
      final data = await Supabase.instance.client
          .from(SupabaseConstants.terrainTable)
          .select('Nom')
          .eq('id', widget.reservation.terrain!)
          .single();
      if (mounted) {
        setState(() => _terrainName = data['Nom'] as String?);
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

  @override
  Widget build(BuildContext context) {
    final c = WColors.of(context);
    final r = widget.reservation;
    final dateStr = r.dateDeResa != null
        ? DateFormat('dd MMM yyyy', 'fr').format(r.dateDeResa!)
        : '';
    final heureStr = r.heureDebut != null ? _formatHour(r.heureDebut!) : '';
    final sport = r.sport ?? 'Match';

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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: c.primaryBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                _sportEmoji(r.sport),
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),
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
                const SizedBox(height: 3),
                if (_terrainName != null)
                  Text(
                    _terrainName!,
                    style: TextStyle(
                      color: c.secondaryText,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _pill(Icons.calendar_today_outlined, dateStr, c),
                    if (heureStr.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _pill(Icons.access_time_outlined, heureStr, c),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _presenceColor(r.presence, c).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              r.presence ?? '-',
              style: TextStyle(
                color: _presenceColor(r.presence, c),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String text, WColors c) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: c.secondaryText),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(color: c.secondaryText, fontSize: 11),
        ),
      ],
    );
  }

  String _formatHour(double h) {
    final hour = h.floor();
    final minutes = ((h - hour) * 60).round();
    return '${hour.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  Color _presenceColor(String? presence, WColors c) {
    switch (presence) {
      case 'Valide':
        return successGreen;
      case 'Annulé':
        return Colors.red;
      default:
        return c.secondaryText;
    }
  }
}
