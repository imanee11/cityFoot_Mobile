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
import '../../models/member_model.dart';
import '../../providers/app_state.dart';

class ReservationSheet extends StatefulWidget {
  final ReservationModel reservation;
  final List<InvitationModel> invitations;
  final int? currentMemberId;

  const ReservationSheet({
    super.key,
    required this.reservation,
    required this.invitations,
    this.currentMemberId,
  });

  @override
  State<ReservationSheet> createState() => _ReservationSheetState();
}

class _ReservationSheetState extends State<ReservationSheet> {
  final Map<int, MemberModel> _members = {};
  String? _produitName;
  double? _prix;
  bool _loading = true;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    await Future.wait([_fetchMembers(), _fetchProduit()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _fetchMembers() async {
    final ids = widget.invitations.map((i) => i.invite).toSet().toList();
    if (ids.isEmpty) return;
    try {
      final data = await Supabase.instance.client
          .from(SupabaseConstants.memberTable)
          .select()
          .inFilter('id', ids);
      for (final m in data as List) {
        final member = MemberModel.fromJson(m);
        if (mounted) setState(() => _members[member.id] = member);
      }
    } catch (_) {}
  }

  Future<void> _fetchProduit() async {
    if (widget.reservation.produit == null) return;
    try {
      final data = await Supabase.instance.client
          .from(SupabaseConstants.produitTable)
          .select()
          .eq('id', widget.reservation.produit!)
          .single();
      if (mounted) {
        setState(() {
          _produitName = data['Nom'] as String?;
          _prix = (data['Prix unitaire'] as num?)?.toDouble();
        });
      }
    } catch (_) {}
  }

  bool get _isCapitaine =>
      widget.currentMemberId != null &&
      widget.currentMemberId == widget.reservation.capitaine;

  int get _maxPlayers {
    final sport = widget.reservation.sport?.toLowerCase();
    if (sport == 'padel') return 4;
    return widget.reservation.joueurs ?? 10;
  }

  String _dateLabel() {
    final dt = widget.reservation.matchDatetime ?? widget.reservation.dateDeResa;
    if (dt == null) return '';
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

  Future<void> _annulerMatch() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Annuler le match?',
      body: 'Cette action est irréversible. Le match sera supprimé pour tous les joueurs.',
      confirmLabel: 'Annuler le match',
    );
    if (!confirmed) return;
    setState(() => _actionLoading = true);
    try {
      await Supabase.instance.client
          .from(SupabaseConstants.reservationTable)
          .delete()
          .eq('id', widget.reservation.id);
      if (mounted) {
        context.read<AppState>().markReservationCreated();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, 'Erreur: ${e.toString()}');
        setState(() => _actionLoading = false);
      }
    }
  }

  Future<void> _quitterMatch() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Quitter le match?',
      body: 'Vous allez quitter ce match. Êtes-vous sûr?',
      confirmLabel: 'Quitter',
    );
    if (!confirmed) return;
    setState(() => _actionLoading = true);
    try {
      final memberId = widget.currentMemberId;
      if (memberId == null) return;

      if (_isCapitaine) {
        final accepted = widget.invitations.where((i) => i.statut == 'accepté').toList();
        if (accepted.isEmpty) {
          await Supabase.instance.client
              .from(SupabaseConstants.reservationTable)
              .delete()
              .eq('id', widget.reservation.id);
        } else {
          final newCapId = accepted.first.invite;

          String? newPrenom, newNom;
          try {
            final memberData = await Supabase.instance.client
                .from(SupabaseConstants.memberTable)
                .select('Prénom, Nom')
                .eq('id', newCapId)
                .single();
            newPrenom = memberData['Prénom'] as String?;
            newNom = memberData['Nom'] as String?;
          } catch (_) {}

          final newTitre = '${newPrenom ?? ''} ${newNom ?? ''}'.trim();

          await Supabase.instance.client
              .from(SupabaseConstants.reservationTable)
              .update({
                'Capitaine': newCapId,
                'Client': newCapId,
                if (newPrenom != null) 'Prénom': newPrenom,
                if (newNom != null) 'Nom': newNom,
                if (newTitre.isNotEmpty) 'Titre': newTitre,
              })
              .eq('id', widget.reservation.id);

          await Supabase.instance.client
              .from(SupabaseConstants.invitationTable)
              .delete()
              .eq('Réservation', widget.reservation.id)
              .eq('Invité', newCapId);
        }
      } else {
        await Supabase.instance.client
            .from(SupabaseConstants.invitationTable)
            .delete()
            .eq('Réservation', widget.reservation.id)
            .eq('Invité', memberId);
      }

      if (mounted) {
        context.read<AppState>().markReservationCreated();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, 'Erreur: ${e.toString()}');
        setState(() => _actionLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = WColors.of(context);
    final r = widget.reservation;
    final emoji = sportEmoji(r.sport);
    final sportName = _sportDisplay(r.sport);
    final timeStr = r.heureDebut != null ? formatHour(r.heureDebut!) : '';
    final dateLabel = _dateLabel();
    final acceptedCount = widget.invitations.where((i) => i.statut == 'accepté').length + 1;
    final filledCount = widget.invitations.length + 1;
    final maxPlayers = _maxPlayers;

    return Container(
      decoration: BoxDecoration(
        color: c.primaryBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: c.borderInput, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),

            // Sport emoji + name
            Row(
              children: [
                emoji.isNotEmpty
                    ? Text(emoji, style: const TextStyle(fontSize: 32))
                    : Icon(Icons.sports, size: 32, color: c.secondaryText),
                const SizedBox(width: 14),
                Text(sportName, style: TextStyle(color: c.primaryText, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),

            // Date + time
            _infoRow(Icons.access_time_outlined, '$dateLabel  $timeStr', c),
            if (_produitName != null) ...[
              const SizedBox(height: 8),
              _infoRow(Icons.location_on_outlined, _produitName!, c),
            ],
            if (_prix != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_money_outlined, size: 16, color: c.secondaryText),
                  const SizedBox(width: 8),
                  Text('${_prix!.toStringAsFixed(0)} MAD',
                      style: const TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
            ],
            const SizedBox(height: 20),

            // Players header
            Text(
              'Joueurs ($filledCount/$maxPlayers) · $acceptedCount confirmés',
              style: TextStyle(color: c.primaryText, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),

            // Toi row — always first, always confirmed
            _playerRow('T', 'Toi', 'accepté', c),
            const SizedBox(height: 8),

            // Invited players
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: primary)))
            else
              ...widget.invitations.map((inv) {
                final member = _members[inv.invite];
                final name = member?.prenom ?? 'Joueur';
                final initials = member != null ? getInitials(member.prenom, member.nom) : '?';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _playerRow(initials, name, inv.statut, c),
                );
              }),

            const SizedBox(height: 16),

            // Action buttons
            if (_actionLoading)
              const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: primary)))
            else
              Row(
                children: [
                  if (_isCapitaine) ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _annulerMatch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: c.secondaryBackground,
                          foregroundColor: errorRed,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(double.infinity, 45),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text('Annuler le match', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _quitterMatch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.secondaryBackground,
                        foregroundColor: c.primaryText,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 45),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text('Quitter le match', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, WColors c) => Row(
    children: [
      Icon(icon, size: 16, color: c.secondaryText),
      const SizedBox(width: 8),
      Text(text, style: TextStyle(color: c.primaryText, fontSize: 14)),
    ],
  );

  Widget _playerRow(String initials, String name, String statut, WColors c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: c.secondaryBackground,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: c.cardBorder),
    ),
    child: Row(
      children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: c.circleColor, shape: BoxShape.circle),
          child: Center(
            child: Text(initials, style: TextStyle(color: c.secondary, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(name, style: TextStyle(color: c.primaryText, fontSize: 14))),
        _statusIcon(statut),
      ],
    ),
  );

  Widget _statusIcon(String statut) {
    switch (statut) {
      case 'accepté':
        return const Icon(Icons.check_circle_outline, color: Color(0xFF22C55E), size: 24);
      case 'refusé':
        return const Icon(Icons.cancel_outlined, color: errorRed, size: 24);
      default:
        return const Icon(Icons.access_time_outlined, color: Colors.orange, size: 24);
    }
  }
}
