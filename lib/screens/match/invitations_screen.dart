import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/supabase_constants.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/initials_helper.dart';
import '../../models/invitation_model.dart';
import '../../models/member_model.dart';
import '../../models/reservation_model.dart';
import '../../providers/app_state.dart';

class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  List<InvitationModel> _invitations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchInvitations());
  }

  Future<void> _fetchInvitations() async {
    final memberId = context.read<AppState>().currentMemberID;
    if (memberId == null) return;
    try {
      final data = await Supabase.instance.client
          .from(SupabaseConstants.invitationTable)
          .select()
          .eq('Invité', memberId)
          .order('created_at', ascending: false);
      final list = (data as List).map((e) => InvitationModel.fromJson(e)).toList();
      if (mounted) {
        setState(() {
          _invitations = list;
          _loading = false;
        });
        context.read<AppState>().setPendingInvitationsCount(
          list.where((i) => i.statut == 'en attente').length,
        );
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = WColors.of(context);
    return Scaffold(
      backgroundColor: c.primaryBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Invitations',
                    style: TextStyle(color: c.primaryText, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  if (_loading)
                    const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: primary, strokeWidth: 2),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Text(
                '${_invitations.length} invitation${_invitations.length != 1 ? 's' : ''}',
                style: TextStyle(color: c.secondaryText, fontSize: 13),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: primary))
                  : _invitations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('✉️', style: TextStyle(fontSize: 40)),
                              const SizedBox(height: 12),
                              Text(
                                'Aucune invitation',
                                style: TextStyle(color: c.secondaryText, fontSize: 15),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: primary,
                          onRefresh: _fetchInvitations,
                          child: ListView.builder(
                            itemCount: _invitations.length,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemBuilder: (context, index) => _InvitationCard(
                              invitation: _invitations[index],
                              onStatusChanged: _fetchInvitations,
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvitationCard extends StatefulWidget {
  final InvitationModel invitation;
  final VoidCallback onStatusChanged;

  const _InvitationCard({required this.invitation, required this.onStatusChanged});

  @override
  State<_InvitationCard> createState() => _InvitationCardState();
}

class _InvitationCardState extends State<_InvitationCard> {
  MemberModel? _inviteur;
  ReservationModel? _reservation;
  bool _loading = true;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final results = await Future.wait([
        Supabase.instance.client
            .from(SupabaseConstants.memberTable)
            .select()
            .eq('id', widget.invitation.inviteur)
            .single(),
        Supabase.instance.client
            .from(SupabaseConstants.reservationTable)
            .select()
            .eq('id', widget.invitation.reservation)
            .single(),
      ]);
      if (mounted) {
        setState(() {
          _inviteur = MemberModel.fromJson(results[0]);
          _reservation = ReservationModel.fromJson(results[1]);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _updating = true);
    try {
      await Supabase.instance.client
          .from(SupabaseConstants.invitationTable)
          .update({'Statut': status})
          .eq('id', widget.invitation.id);
      widget.onStatusChanged();
    } catch (e) {
      if (mounted) showErrorSnackbar(context, 'Erreur: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = WColors.of(context);
    final inv = widget.invitation;
    final isPending = inv.statut == 'en attente';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: _loading
          ? const Center(child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(color: primary, strokeWidth: 2),
            ))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Inviteur row
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: c.circleColor, shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          getInitials(_inviteur?.prenom, _inviteur?.nom),
                          style: TextStyle(color: c.secondary, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _inviteur?.fullName ?? 'Quelqu\'un',
                            style: TextStyle(color: c.primaryText, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          Text(
                            't\'invite à rejoindre',
                            style: TextStyle(color: c.secondaryText, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (!isPending)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: inv.statut == 'accepté'
                              ? successGreen.withValues(alpha: 0.12)
                              : errorRed.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          inv.statut == 'accepté' ? 'Accepté' : 'Refusé',
                          style: TextStyle(
                            color: inv.statut == 'accepté' ? successGreen : errorRed,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // Match info box
                if (_reservation != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: c.primaryBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(sportEmoji(_reservation!.sport), style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _reservation!.sport ?? 'Match',
                                style: TextStyle(color: c.primaryText, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              if (_reservation!.format != null && _reservation!.format!.isNotEmpty)
                                Text(_reservation!.format!, style: TextStyle(color: c.secondaryText, fontSize: 12)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _reservation!.heureDebut != null ? formatHour(_reservation!.heureDebut!) : '--:--',
                              style: TextStyle(color: c.primaryText, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              _reservation!.matchDatetime != null
                                  ? DateFormat('dd MMM', 'fr').format(_reservation!.matchDatetime!)
                                  : (_reservation!.dateDeResa != null
                                      ? DateFormat('dd MMM', 'fr').format(_reservation!.dateDeResa!)
                                      : ''),
                              style: TextStyle(color: c.secondaryText, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                if (isPending) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _updating ? null : () => _updateStatus('accepté'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: EdgeInsets.zero,
                            ),
                            child: _updating
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check, size: 16),
                                      SizedBox(width: 6),
                                      Text('Accepter', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _updating ? null : () => _updateStatus('refusé'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEEEEEE),
                              foregroundColor: const Color(0xFF555555),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.close, size: 16),
                                SizedBox(width: 6),
                                Text('Refuser', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              ],
                            ),
                          ),
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
