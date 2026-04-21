import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/supabase_constants.dart';
import '../../core/utils/helpers.dart';
import '../../models/reservation_model.dart';
import '../../models/invitation_model.dart';
import '../../providers/app_state.dart';
import 'reservation_sheet.dart';

class MesMatchsScreen extends StatefulWidget {
  const MesMatchsScreen({super.key});

  @override
  State<MesMatchsScreen> createState() => _MesMatchsScreenState();
}

class _MesMatchsScreenState extends State<MesMatchsScreen> {
  List<ReservationModel> _upcoming = [];
  List<ReservationModel> _passed = [];
  bool _loading = true;
  int _lastRefreshId = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAll());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = context.read<AppState>().reservationRefreshId;
    if (id > _lastRefreshId) {
      _lastRefreshId = id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fetchAll();
      });
    }
  }

  Future<void> _fetchAll() async {
    final memberId = context.read<AppState>().currentMemberID;
    if (memberId == null) return;
    setState(() => _loading = true);
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final upData = await Supabase.instance.client
          .from(SupabaseConstants.reservationTable)
          .select()
          .eq('Client', memberId)
          .gte('match_datetime', now)
          .order('match_datetime', ascending: true);
      final passedData = await Supabase.instance.client
          .from(SupabaseConstants.reservationTable)
          .select()
          .eq('Client', memberId)
          .lt('match_datetime', now)
          .order('match_datetime', ascending: false);
      if (mounted) {
        setState(() {
          _upcoming = (upData as List).map((e) => ReservationModel.fromJson(e)).toList();
          _passed = (passedData as List).map((e) => ReservationModel.fromJson(e)).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onCardTap(ReservationModel res) async {
    final appState = context.read<AppState>();
    try {
      final data = await Supabase.instance.client
          .from(SupabaseConstants.invitationTable)
          .select()
          .eq('Réservation', res.id);
      final invitations = (data as List).map((e) => InvitationModel.fromJson(e)).toList();
      final confirmed = invitations.where((i) => i.statut == 'accepté').length;
      appState.setCountPlayers(invitations.length, confirmed);
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => ReservationSheet(reservation: res, invitations: invitations, currentMemberId: appState.currentMemberID),
        );
      }
    } catch (_) {}
  }

  Future<void> _deleteReservation(ReservationModel res) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Supprimer cette réservation?',
      body: 'Les invitations seront automatiquement supprimées.',
      confirmLabel: 'Supprimer',
    );
    if (!confirmed) return;
    try {
      await Supabase.instance.client
          .from(SupabaseConstants.reservationTable)
          .delete()
          .eq('id', res.id);
      setState(() {
        _upcoming.removeWhere((r) => r.id == res.id);
        _passed.removeWhere((r) => r.id == res.id);
      });
      if (mounted) showSuccessSnackbar(context, 'Réservation supprimée');
    } catch (e) {
      if (mounted) showErrorSnackbar(context, 'Erreur: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = WColors.of(context);
    final appState = context.watch<AppState>();
    final isUpcoming = appState.selectedTab == 'tab1';
    final list = isUpcoming ? _upcoming : _passed;

    return Scaffold(
      backgroundColor: c.primaryBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mes Matchs',
                    style: TextStyle(color: c.primaryText, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (_loading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: primary, strokeWidth: 2),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Custom tab switcher
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: c.alternate,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _TabButton(
                      label: 'A venir',
                      isActive: isUpcoming,
                      onTap: () => appState.setSelectedTab('tab1'),
                    ),
                    _TabButton(
                      label: 'Passés',
                      isActive: !isUpcoming,
                      onTap: () => appState.setSelectedTab('tab2'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: primary))
                  : list.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(isUpcoming ? '📅' : '🏁', style: const TextStyle(fontSize: 40)),
                              const SizedBox(height: 12),
                              Text(
                                isUpcoming ? 'Aucun match à venir' : 'Aucun match passé',
                                style: TextStyle(color: c.secondaryText, fontSize: 15),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: list.length,
                          padding: const EdgeInsets.only(bottom: 16),
                          itemBuilder: (context, index) => _MatchCard(
                            reservation: list[index],
                            showDelete: isUpcoming,
                            onTap: () => _onCardTap(list[index]),
                            onDelete: () => _deleteReservation(list[index]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = WColors.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isActive ? primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : c.secondaryText,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchCard extends StatefulWidget {
  final ReservationModel reservation;
  final bool showDelete;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MatchCard({
    required this.reservation,
    required this.showDelete,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<_MatchCard> {
  double? _prix;
  List<String> _playerInitials = [];
  int _confirmedCount = 1;

  @override
  void initState() {
    super.initState();
    _fetchExtras();
  }

  Future<void> _fetchExtras() async {
    final r = widget.reservation;
    await Future.wait([_fetchProduit(r), _fetchPlayers(r)]);
  }

  Future<void> _fetchProduit(ReservationModel r) async {
    if (r.produit == null) return;
    try {
      final d = await Supabase.instance.client
          .from(SupabaseConstants.produitTable)
          .select()
          .eq('id', r.produit!)
          .single();
      if (mounted) {
        setState(() {
          _prix = (d['Prix unitaire'] as num?)?.toDouble();
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchPlayers(ReservationModel r) async {
    try {
      final invData = await Supabase.instance.client
          .from(SupabaseConstants.invitationTable)
          .select('Invité')
          .eq('Réservation', r.id);
      final ids = (invData as List).map((e) => e['Invité'] as int).toList();
      final totalInvited = ids.length;
      if (ids.isEmpty) {
        if (mounted) setState(() => _confirmedCount = 1);
        return;
      }
      final members = await Supabase.instance.client
          .from(SupabaseConstants.memberTable)
          .select('Prénom')
          .inFilter('id', ids.take(3).toList());
      if (mounted) {
        setState(() {
          _confirmedCount = 1 + totalInvited;
          _playerInitials = (members as List).map((m) {
            final p = (m['Prénom'] as String?) ?? '';
            return p.isNotEmpty ? p[0].toUpperCase() : '?';
          }).take(3).toList();
        });
      }
    } catch (_) {}
  }

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return "Aujourd'hui";
    if (d == today.add(const Duration(days: 1))) return 'Demain';
    return DateFormat('dd MMM', 'fr').format(dt);
  }

  String _sportDisplay(String? s) {
    switch (s?.toLowerCase()) {
      case 'foot': return 'Football';
      case 'padel': return 'Padel';
      case 'basket': return 'Basket';
      default: return s ?? 'Match';
    }
  }

  Widget _stackedCircles(WColors c) {
    final labels = ['T', ..._playerInitials];
    const size = 28.0;
    const step = 20.0;
    final totalWidth = size + (labels.length - 1) * step;
    return SizedBox(
      width: totalWidth,
      height: size,
      child: Stack(
        children: List.generate(labels.length, (i) {
          final label = labels[i];
          return Positioned(
            left: i * step,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: c.circleColor,
                shape: BoxShape.circle,
                border: Border.all(color: c.secondaryBackground, width: 2),
              ),
              child: label.isNotEmpty
                  ? Center(child: Text(label, style: TextStyle(color: c.secondary, fontSize: 10, fontWeight: FontWeight.bold)))
                  : null,
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = WColors.of(context);
    final r = widget.reservation;
    final emoji = sportEmoji(r.sport);
    final timeStr = r.heureDebut != null ? formatHour(r.heureDebut!) : '';
    final dateLabel = r.matchDatetime != null ? _dateLabel(r.matchDatetime!) : '';

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: c.secondaryBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.cardBorder),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                emoji.isNotEmpty
                    ? Text(emoji, style: const TextStyle(fontSize: 22))
                    : Icon(Icons.sports, size: 22, color: c.secondaryText),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_sportDisplay(r.sport), style: TextStyle(color: c.primaryText, fontWeight: FontWeight.bold, fontSize: 14)),
                      Builder(builder: (_) {
                        final parts = <String>[];
                        if (r.joueurs != null) parts.add('${r.joueurs} joueurs');
                        if (r.format != null && r.format!.isNotEmpty) parts.add(r.format!);
                        final subtitle = parts.join('  ');
                        if (subtitle.isEmpty) return const SizedBox.shrink();
                        return Text(subtitle, style: TextStyle(color: c.secondaryText, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis);
                      }),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(timeStr, style: TextStyle(color: c.primaryText, fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(dateLabel, style: TextStyle(color: c.secondaryText, fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _stackedCircles(c),
                const SizedBox(width: 8),
                Text(
                  '$_confirmedCount/${widget.reservation.joueurs ?? (widget.reservation.sport?.toLowerCase() == 'padel' ? 4 : 10)}',
                  style: TextStyle(color: c.secondaryText, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                if (_prix != null)
                  Text('${_prix!.toStringAsFixed(0)} MAD', style: const TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
