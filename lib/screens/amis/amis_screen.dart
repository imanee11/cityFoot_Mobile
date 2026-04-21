import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/supabase_constants.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/initials_helper.dart';
import '../../models/amis_model.dart';
import '../../models/member_model.dart';
import '../../providers/app_state.dart';
import 'ajouter_amis_screen.dart';

class AmisScreen extends StatefulWidget {
  const AmisScreen({super.key});

  @override
  State<AmisScreen> createState() => _AmisScreenState();
}

class _AmisScreenState extends State<AmisScreen> {
  List<AmisModel> _mesAmis = [];
  List<AmisModel> _demandesRecues = [];
  List<AmisModel> _demandesEnvoyees = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAll());
  }

  Future<void> _fetchAll() async {
    final appState = context.read<AppState>();
    final memberId = appState.currentMemberID;
    if (memberId == null) return;
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        Supabase.instance.client
            .from(SupabaseConstants.mesAmisView)
            .select()
            .or('Demandeur.eq.$memberId,Destinataire.eq.$memberId'),
        Supabase.instance.client
            .from(SupabaseConstants.amisTable)
            .select()
            .eq('Destinataire', memberId)
            .eq('Statut', 'en attente'),
        Supabase.instance.client
            .from(SupabaseConstants.amisTable)
            .select()
            .eq('Demandeur', memberId)
            .eq('Statut', 'en attente'),
        Supabase.instance.client
            .from(SupabaseConstants.invitationTable)
            .select('id')
            .eq('Invité', memberId)
            .eq('Statut', 'en attente'),
      ]);

      final amis = (results[0] as List).map((e) => AmisModel.fromJson(e)).toList();
      final recues = (results[1] as List).map((e) => AmisModel.fromJson(e)).toList();
      final envoyees = (results[2] as List).map((e) => AmisModel.fromJson(e)).toList();
      final pendingCount = (results[3] as List).length;

      if (mounted) {
        setState(() {
          _mesAmis = amis;
          _demandesRecues = recues;
          _demandesEnvoyees = envoyees;
          _loading = false;
        });
        appState.setMesAmisCount(amis.length);
        appState.setDemandesCount(recues.length);
        appState.setPendingInvitationsCount(pendingCount);
        appState.setVisibleTrash(false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _accepterDemande(AmisModel ami) async {
    final appState = context.read<AppState>();
    try {
      await Supabase.instance.client
          .from(SupabaseConstants.amisTable)
          .update({'Statut': 'accepté'})
          .eq('id', ami.id);
      try {
        final data = await Supabase.instance.client
            .from(SupabaseConstants.memberTable)
            .select('Téléphone')
            .eq('id', ami.demandeur)
            .single();
        final phone = data['Téléphone'] as String? ?? '';
        if (phone.isNotEmpty) {
          // Notification sent silently
        }
      } catch (_) {}

      setState(() {
        _demandesRecues.removeWhere((d) => d.id == ami.id);
      });
      appState.setDemandesCount(_demandesRecues.length);
      await _fetchAll();
    } catch (e) {
      if (mounted) showErrorSnackbar(context, 'Erreur: ${e.toString()}');
    }
  }

  Future<void> _refuserDemande(AmisModel ami) async {
    final appState = context.read<AppState>();
    try {
      await Supabase.instance.client
          .from(SupabaseConstants.amisTable)
          .update({'Statut': 'refusé'})
          .eq('id', ami.id);
      setState(() => _demandesRecues.removeWhere((d) => d.id == ami.id));
      appState.setDemandesCount(_demandesRecues.length);
    } catch (e) {
      if (mounted) showErrorSnackbar(context, 'Erreur: ${e.toString()}');
    }
  }

  Future<void> _annulerDemande(AmisModel ami) async {
    try {
      await Supabase.instance.client
          .from(SupabaseConstants.amisTable)
          .delete()
          .eq('id', ami.id);
      setState(() => _demandesEnvoyees.removeWhere((d) => d.id == ami.id));
    } catch (e) {
      if (mounted) showErrorSnackbar(context, 'Erreur: ${e.toString()}');
    }
  }

  Future<void> _supprimerAmi(AmisModel ami) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Supprimer cet ami?',
      body: 'Cette action est irréversible.',
      confirmLabel: 'Supprimer',
    );
    if (!confirmed) return;
    try {
      await Supabase.instance.client
          .from(SupabaseConstants.amisTable)
          .delete()
          .eq('id', ami.id);
      if (!mounted) return;
      setState(() => _mesAmis.removeWhere((a) => a.id == ami.id));
      context.read<AppState>().setMesAmisCount(_mesAmis.length);
    } catch (e) {
      if (mounted) showErrorSnackbar(context, 'Erreur: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = WColors.of(context);
    final appState = context.watch<AppState>();
    final isAmis = appState.selectedTabAmis == 'amis';
    final demandesCount = _demandesRecues.length + _demandesEnvoyees.length;

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
                    'Amis',
                    style: TextStyle(color: c.primaryText, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c.secondaryBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.person_add_outlined, color: c.primaryText, size: 18),
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AjouterAmisScreen()),
                        );
                        _fetchAll();
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tab switcher
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
                    Expanded(
                      child: GestureDetector(
                        onTap: () => appState.setSelectedTabAmis('amis'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isAmis ? primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Center(
                            child: Text(
                              'Amis (${_mesAmis.length})',
                              style: TextStyle(
                                color: isAmis ? Colors.white : c.secondaryText,
                                fontWeight: isAmis ? FontWeight.bold : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => appState.setSelectedTabAmis('demandes'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: !isAmis ? primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Demandes',
                                  style: TextStyle(
                                    color: !isAmis ? Colors.white : c.secondaryText,
                                    fontWeight: !isAmis ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                if (demandesCount > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(
                                      color: errorRed,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$demandesCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: primary))
                  : isAmis
                      ? _buildAmisTab(appState)
                      : _buildDemandesTab(c),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmisTab(AppState appState) {
    final c = WColors.of(context);
    if (_mesAmis.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👥', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text('Aucun ami pour le moment', style: TextStyle(color: c.secondaryText, fontSize: 15)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _mesAmis.length,
      padding: const EdgeInsets.only(bottom: 16),
      itemBuilder: (context, index) {
        final ami = _mesAmis[index];
        return _AmiCard(
          amiRow: ami,
          showTrash: appState.visibleTrash,
          onDelete: () => _supprimerAmi(ami),
          onLongPress: () => appState.toggleVisibleTrash(),
        );
      },
    );
  }

  Widget _buildDemandesTab(WColors c) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        if (_demandesRecues.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              'Demandes reçues',
              style: TextStyle(color: c.secondaryText, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          ..._demandesRecues.map((d) => _DemandeCard(
                amiRow: d,
                memberId: d.demandeur,
                onAccepter: () => _accepterDemande(d),
                onRefuser: () => _refuserDemande(d),
              )),
        ],
        if (_demandesEnvoyees.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Demandes envoyées',
              style: TextStyle(color: c.secondaryText, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          ..._demandesEnvoyees.map((d) => _DemandeEnvoyeeCard(
                amiRow: d,
                memberId: d.destinataire,
                onAnnuler: () => _annulerDemande(d),
              )),
        ],
        if (_demandesRecues.isEmpty && _demandesEnvoyees.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text('Aucune demande en attente', style: TextStyle(color: c.secondaryText, fontSize: 15)),
            ),
          ),
      ],
    );
  }
}

class _AmiCard extends StatefulWidget {
  final AmisModel amiRow;
  final bool showTrash;
  final VoidCallback onDelete;
  final VoidCallback onLongPress;

  const _AmiCard({
    required this.amiRow,
    required this.showTrash,
    required this.onDelete,
    required this.onLongPress,
  });

  @override
  State<_AmiCard> createState() => _AmiCardState();
}

class _AmiCardState extends State<_AmiCard> {
  MemberModel? _member;

  @override
  void initState() {
    super.initState();
    _fetchMember();
  }

  Future<void> _fetchMember() async {
    final amiId = widget.amiRow.amiId;
    if (amiId == null) return;
    try {
      final data = await Supabase.instance.client
          .from(SupabaseConstants.memberTable)
          .select()
          .eq('id', amiId)
          .single();
      if (mounted) setState(() => _member = MemberModel.fromJson(data));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final c = WColors.of(context);
    final initials = _member != null
        ? getInitials(_member!.prenom, _member!.nom)
        : '?';

    return GestureDetector(
      onLongPress: widget.onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: c.secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: c.circleColor, shape: BoxShape.circle),
              child: Center(
                child: Text(initials, style: TextStyle(color: c.secondary, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _member?.fullName ?? '...',
                style: TextStyle(color: c.primaryText, fontWeight: FontWeight.w500, fontSize: 14),
              ),
            ),
            if (widget.showTrash)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.delete_outline, color: errorRed, size: 20),
                onPressed: widget.onDelete,
              ),
          ],
        ),
      ),
    );
  }
}

class _DemandeCard extends StatefulWidget {
  final AmisModel amiRow;
  final int memberId;
  final VoidCallback onAccepter;
  final VoidCallback onRefuser;

  const _DemandeCard({
    required this.amiRow,
    required this.memberId,
    required this.onAccepter,
    required this.onRefuser,
  });

  @override
  State<_DemandeCard> createState() => _DemandeCardState();
}

class _DemandeCardState extends State<_DemandeCard> {
  MemberModel? _member;

  @override
  void initState() {
    super.initState();
    _fetchMember();
  }

  Future<void> _fetchMember() async {
    try {
      final data = await Supabase.instance.client
          .from(SupabaseConstants.memberTable)
          .select()
          .eq('id', widget.memberId)
          .single();
      if (mounted) setState(() => _member = MemberModel.fromJson(data));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final c = WColors.of(context);
    final initials = _member != null ? getInitials(_member!.prenom, _member!.nom) : '?';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: c.circleColor, shape: BoxShape.circle),
            child: Center(
              child: Text(initials, style: TextStyle(color: c.secondary, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _member?.fullName ?? '...',
              style: TextStyle(color: c.primaryText, fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: widget.onRefuser,
            style: TextButton.styleFrom(
              foregroundColor: c.secondaryText,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              side: BorderSide(color: c.borderInput),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Refuser', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 6),
          ElevatedButton(
            onPressed: widget.onAccepter,
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
              minimumSize: Size.zero,
            ),
            child: const Text('Accepter', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _DemandeEnvoyeeCard extends StatefulWidget {
  final AmisModel amiRow;
  final int memberId;
  final VoidCallback onAnnuler;

  const _DemandeEnvoyeeCard({
    required this.amiRow,
    required this.memberId,
    required this.onAnnuler,
  });

  @override
  State<_DemandeEnvoyeeCard> createState() => _DemandeEnvoyeeCardState();
}

class _DemandeEnvoyeeCardState extends State<_DemandeEnvoyeeCard> {
  MemberModel? _member;

  @override
  void initState() {
    super.initState();
    _fetchMember();
  }

  Future<void> _fetchMember() async {
    try {
      final data = await Supabase.instance.client
          .from(SupabaseConstants.memberTable)
          .select()
          .eq('id', widget.memberId)
          .single();
      if (mounted) setState(() => _member = MemberModel.fromJson(data));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final c = WColors.of(context);
    final initials = _member != null ? getInitials(_member!.prenom, _member!.nom) : '?';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: c.circleColor, shape: BoxShape.circle),
            child: Center(
              child: Text(initials, style: TextStyle(color: c.secondary, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _member?.fullName ?? '...',
              style: TextStyle(color: c.primaryText, fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: c.secondaryText.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('En attente', style: TextStyle(color: c.secondaryText, fontSize: 11)),
          ),
          const SizedBox(width: 6),
          TextButton(
            onPressed: widget.onAnnuler,
            style: TextButton.styleFrom(
              foregroundColor: errorRed,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
            ),
            child: const Text('Annuler', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
