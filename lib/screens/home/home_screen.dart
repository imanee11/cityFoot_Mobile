import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/supabase_constants.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/initials_helper.dart';
import '../../models/reservation_model.dart';
import '../../models/invitation_model.dart';

import '../../providers/app_state.dart';
import '../match/creer_match_screen.dart';
import '../match/reservation_sheet.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToMatchs;

  const HomeScreen({super.key, this.onNavigateToMatchs});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ReservationModel> _upcoming = [];
  bool _loadingMatchs = true;
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
    final appState = context.read<AppState>();
    final memberId = appState.currentMemberID;
    if (memberId == null) return;
    await _fetchMatchs(memberId);
  }

  Future<void> _fetchMatchs(int memberId) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final data = await Supabase.instance.client
          .from(SupabaseConstants.reservationTable)
          .select()
          .eq('Client', memberId)
          .gte('match_datetime', now)
          .order('match_datetime', ascending: true)
          .limit(3);
      final list = (data as List).map((e) => ReservationModel.fromJson(e)).toList();
      if (mounted) setState(() { _upcoming = list; _loadingMatchs = false; });
    } catch (e) {
      if (mounted) setState(() => _loadingMatchs = false);
    }
  }

  Future<void> _onReservationTap(ReservationModel res) async {
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

  @override
  Widget build(BuildContext context) {
    final c = WColors.of(context);
    final appState = context.watch<AppState>();
    final initials = getInitials(appState.currentMemberName, appState.currentMemberlastName);

    return Scaffold(
      backgroundColor: c.primaryBackground,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const CreerMatchScreen(),
        ),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        icon: const Icon(Icons.add),
        label: const Text('Créer une réservation', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Oasis',
                                  style: TextStyle(
                                    color: c.primaryText,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const TextSpan(
                                  text: 'Sports',
                                  style: TextStyle(
                                    color: primary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Salut, ${appState.currentMemberName}',
                            style: TextStyle(color: c.secondaryText, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c.circleColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: TextStyle(
                            color: c.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Promo banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primary, Color(0xFF14225D)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Icon(Icons.campaign_outlined, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🎉 Nouveau terrain de Padel !',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Le Court Padel 2 est maintenant disponible. Réservez dès maintenant avec -20% cette semaine !',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Mes prochains matchs header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mes prochains matchs',
                      style: TextStyle(color: c.primaryText, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    GestureDetector(
                      onTap: widget.onNavigateToMatchs,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Voir tout',
                            style: TextStyle(color: primary, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          SizedBox(width: 2),
                          Icon(Icons.chevron_right, color: primary, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Upcoming matches
            if (_loadingMatchs)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: primary),
                  ),
                ),
              )
            else if (_upcoming.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: _EmptyMatchCard(),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _HomeMatchCard(
                    key: ValueKey(_upcoming[index].id),
                    reservation: _upcoming[index],
                    onTap: () => _onReservationTap(_upcoming[index]),
                  ),
                  childCount: _upcoming.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _EmptyMatchCard extends StatelessWidget {
  const _EmptyMatchCard();

  @override
  Widget build(BuildContext context) {
    final c = WColors.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.secondaryBackground,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: c.borderInput),
      ),
      child: Column(
        children: [
          const Text('⚽', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text('Aucun match à venir', style: TextStyle(color: c.secondaryText, fontSize: 14)),
        ],
      ),
    );
  }
}

class _HomeMatchCard extends StatefulWidget {
  final ReservationModel reservation;
  final VoidCallback onTap;

  const _HomeMatchCard({super.key, required this.reservation, required this.onTap});

  @override
  State<_HomeMatchCard> createState() => _HomeMatchCardState();
}

class _HomeMatchCardState extends State<_HomeMatchCard> {
  double? _prix;
  List<String> _playerInitials = [];
  int _confirmedCount = 1; // 1 = capitaine

  @override
  void initState() {
    super.initState();
    _fetchExtras();
  }

  Future<void> _fetchExtras() async {
    final r = widget.reservation;
    await Future.wait([_fetchProduit(r), _fetchPlayers(r)]);
  }

  Future<void> _fetchProduit(ReservationModel reservation) async {
    if (reservation.produit == null) return;
    try {
      final data = await Supabase.instance.client
          .from(SupabaseConstants.produitTable)
          .select()
          .eq('id', reservation.produit!)
          .single();
      if (mounted) {
        setState(() {
          _prix = (data['Prix unitaire'] as num?)?.toDouble();
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchPlayers(ReservationModel reservation) async {
    try {
      final invData = await Supabase.instance.client
          .from(SupabaseConstants.invitationTable)
          .select('Invité')
          .eq('Réservation', reservation.id);
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
