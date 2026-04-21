import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/supabase_constants.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/initials_helper.dart';
import '../../models/terrain_model.dart';
import '../../models/produit_model.dart';
import '../../models/amis_model.dart';
import '../../models/member_model.dart';
import '../../providers/app_state.dart';
import '../../core/services/notification_service.dart';

class ReserverScreen extends StatefulWidget {
  final TerrainModel terrain;

  const ReserverScreen({super.key, required this.terrain});

  @override
  State<ReserverScreen> createState() => _ReserverScreenState();
}

class _ReserverScreenState extends State<ReserverScreen> {
  final PageController _pageCtrl = PageController();
  int _step = 0;

  List<ProduitModel> _produits = [];
  ProduitModel? _selectedProduit;
  bool _loadingProduits = true;

  DateTime? _selectedDate;

  List<_AmiWithMember> _amis = [];
  final Set<int> _selectedAmiIds = {};
  bool _loadingAmis = false;

  bool _booking = false;

  @override
  void initState() {
    super.initState();
    _fetchProduits();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchProduits() async {
    try {
      final data = await Supabase.instance.client
          .from(SupabaseConstants.produitTable)
          .select()
          .eq('Terrain', widget.terrain.id);
      if (mounted) {
        setState(() {
          _produits = (data as List).map((e) => ProduitModel.fromJson(e)).toList();
          _loadingProduits = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProduits = false);
    }
  }

  Future<void> _fetchAmis() async {
    final appState = context.read<AppState>();
    final memberId = appState.currentMemberID;
    if (memberId == null) return;
    setState(() => _loadingAmis = true);
    try {
      final amiData = await Supabase.instance.client
          .from(SupabaseConstants.mesAmisView)
          .select()
          .or('Demandeur.eq.$memberId,Destinataire.eq.$memberId');

      final rows = (amiData as List).map((e) => AmisModel.fromJson(e)).toList();
      final List<_AmiWithMember> result = [];
      for (final row in rows) {
        if (row.amiId == null) continue;
        try {
          final mData = await Supabase.instance.client
              .from(SupabaseConstants.memberTable)
              .select()
              .eq('id', row.amiId!)
              .single();
          result.add(_AmiWithMember(ami: row, member: MemberModel.fromJson(mData)));
        } catch (_) {}
      }
      if (mounted) setState(() { _amis = result; _loadingAmis = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingAmis = false);
    }
  }

  void _goToStep(int step) {
    setState(() => _step = step);
    _pageCtrl.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: primary),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _terminer() async {
    if (_selectedProduit == null || _selectedDate == null) return;
    final appState = context.read<AppState>();
    final memberId = appState.currentMemberID;
    if (memberId == null) return;

    setState(() => _booking = true);
    try {
      final p = _selectedProduit!;
      final startHour = p.startAt ?? 8.0;
      final endHour = p.endAt ?? 9.0;
      final duree = endHour - startHour;

      final dateDeResa = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        startHour.floor(),
        ((startHour - startHour.floor()) * 60).round(),
      );

      final insertData = {
        'Client': memberId,
        'Capitaine': memberId,
        'Joueurs': memberId,
        'Sport': widget.terrain.sport ?? p.sport ?? '',
        'Produit': p.id,
        'Terrain': widget.terrain.id,
        'Date de résa': dateDeResa.toIso8601String(),
        'Heure_début': startHour,
        'Heure_fin': endHour,
        'Durée': duree,
        'Présence': 'Valide',
        'Privé_Public': 'Privé',
        'Titre': '${widget.terrain.nom ?? ''} - ${p.nom ?? ''}',
      };

      final res = await Supabase.instance.client
          .from(SupabaseConstants.reservationTable)
          .insert(insertData)
          .select('id')
          .single();
      final reservationId = res['id'] as String;

      for (final amiId in _selectedAmiIds) {
        final ami = _amis.firstWhere((a) => a.member.id == amiId, orElse: () => _amis.first);
        try {
          await Supabase.instance.client.from(SupabaseConstants.invitationTable).insert({
            'Réservation': reservationId,
            'Invité': amiId,
            'Inviteur': memberId,
            'Statut': 'en attente',
          });
          await NotificationService.sendWhatsApp(
            phone: ami.member.telephone ?? '',
            title: 'Invitation à un match',
            body: '${appState.currentMemberName} vous invite à un match sur OasisSports',
          );
        } catch (_) {}
      }

      if (mounted) {
        showSuccessSnackbar(context, 'Réservation effectuée avec succès!');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showErrorSnackbar(context, 'Erreur: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = WColors.of(context);
    return Scaffold(
      backgroundColor: c.primaryBackground,
      appBar: AppBar(
        backgroundColor: c.secondaryBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: c.primaryText),
        title: Text(
          'Réserver — ${widget.terrain.nom ?? ''}',
          style: TextStyle(color: c.primaryText, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / 4,
            backgroundColor: c.alternate,
            color: primary,
            minHeight: 4,
          ),
        ),
      ),
      body: PageView(
        controller: _pageCtrl,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _StepProduit(
            produits: _produits,
            loading: _loadingProduits,
            selected: _selectedProduit,
            onSelect: (p) {
              setState(() => _selectedProduit = p);
              _goToStep(1);
            },
          ),
          _StepDate(
            selectedDate: _selectedDate,
            selectedProduit: _selectedProduit,
            onPickDate: _pickDate,
            onNext: () {
              if (_selectedDate == null) {
                showErrorSnackbar(context, 'Veuillez sélectionner une date');
                return;
              }
              _fetchAmis();
              _goToStep(2);
            },
            onBack: () => _goToStep(0),
          ),
          _StepAmis(
            amis: _amis,
            loading: _loadingAmis,
            selectedIds: _selectedAmiIds,
            onToggle: (id) => setState(() {
              if (_selectedAmiIds.contains(id)) {
                _selectedAmiIds.remove(id);
              } else {
                _selectedAmiIds.add(id);
              }
            }),
            onNext: () => _goToStep(3),
            onBack: () => _goToStep(1),
          ),
          _StepConfirm(
            terrain: widget.terrain,
            produit: _selectedProduit,
            date: _selectedDate,
            selectedCount: _selectedAmiIds.length,
            booking: _booking,
            onConfirm: _terminer,
            onBack: () => _goToStep(2),
          ),
        ],
      ),
    );
  }
}

class _StepProduit extends StatelessWidget {
  final List<ProduitModel> produits;
  final bool loading;
  final ProduitModel? selected;
  final ValueChanged<ProduitModel> onSelect;

  const _StepProduit({
    required this.produits,
    required this.loading,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final c = WColors.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choisir un créneau', style: TextStyle(color: c.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Sélectionnez un horaire disponible', style: TextStyle(color: c.secondaryText, fontSize: 13)),
          const SizedBox(height: 20),
          if (loading)
            const Center(child: CircularProgressIndicator(color: primary))
          else if (produits.isEmpty)
            Center(child: Text('Aucun créneau disponible', style: TextStyle(color: c.secondaryText)))
          else
            ...produits.map((p) {
              final isSelected = selected?.id == p.id;
              return GestureDetector(
                onTap: () => onSelect(p),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected ? primary.withValues(alpha: 0.08) : c.secondaryBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? primary : c.borderInput,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.nom ?? 'Créneau', style: TextStyle(color: c.primaryText, fontWeight: FontWeight.w600, fontSize: 14)),
                            if (p.startAt != null && p.endAt != null) ...[
                              const SizedBox(height: 3),
                              Text('${formatHour(p.startAt!)} → ${formatHour(p.endAt!)}', style: TextStyle(color: c.secondaryText, fontSize: 12)),
                            ],
                            if (p.sport != null) ...[
                              const SizedBox(height: 3),
                              Text(p.sport!, style: TextStyle(color: c.secondaryText, fontSize: 12)),
                            ],
                          ],
                        ),
                      ),
                      if (p.prixUnitaire != null)
                        Text('${p.prixUnitaire!.toStringAsFixed(0)} DH', style: const TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(width: 8),
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: isSelected ? primary : c.secondaryText,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _StepDate extends StatelessWidget {
  final DateTime? selectedDate;
  final ProduitModel? selectedProduit;
  final VoidCallback onPickDate;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _StepDate({
    required this.selectedDate,
    required this.selectedProduit,
    required this.onPickDate,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final c = WColors.of(context);
    final dateStr = selectedDate != null
        ? DateFormat('dd MMMM yyyy', 'fr').format(selectedDate!)
        : null;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choisir une date', style: TextStyle(color: c.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Sélectionnez la date de votre réservation', style: TextStyle(color: c.secondaryText, fontSize: 13)),
          const SizedBox(height: 24),

          if (selectedProduit != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: primary, size: 18),
                  const SizedBox(width: 10),
                  Text(selectedProduit!.nom ?? 'Créneau sélectionné', style: TextStyle(color: c.primaryText, fontWeight: FontWeight.w500)),
                  if (selectedProduit!.startAt != null && selectedProduit!.endAt != null) ...[
                    const Spacer(),
                    Text(
                      '${formatHour(selectedProduit!.startAt!)}–${formatHour(selectedProduit!.endAt!)}',
                      style: const TextStyle(color: primary, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),

          const SizedBox(height: 20),

          GestureDetector(
            onTap: onPickDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.secondaryBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selectedDate != null ? primary : c.borderInput),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined, color: selectedDate != null ? primary : c.secondaryText, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    dateStr ?? 'Sélectionner une date',
                    style: TextStyle(
                      color: selectedDate != null ? c.primaryText : c.secondaryText,
                      fontSize: 15,
                      fontWeight: selectedDate != null ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.secondaryText,
                    side: BorderSide(color: c.borderInput),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Retour'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: const Text('Suivant', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmiWithMember {
  final AmisModel ami;
  final MemberModel member;
  const _AmiWithMember({required this.ami, required this.member});
}

class _StepAmis extends StatelessWidget {
  final List<_AmiWithMember> amis;
  final bool loading;
  final Set<int> selectedIds;
  final ValueChanged<int> onToggle;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _StepAmis({
    required this.amis,
    required this.loading,
    required this.selectedIds,
    required this.onToggle,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final c = WColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Inviter des amis', style: TextStyle(color: c.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Sélectionnez les amis à inviter (optionnel)', style: TextStyle(color: c.secondaryText, fontSize: 13)),
          const SizedBox(height: 20),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator(color: primary))
                : amis.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('👥', style: TextStyle(fontSize: 36)),
                            const SizedBox(height: 8),
                            Text('Aucun ami disponible', style: TextStyle(color: c.secondaryText)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: amis.length,
                        itemBuilder: (context, index) {
                          final item = amis[index];
                          final isSelected = selectedIds.contains(item.member.id);
                          final initials = getInitials(item.member.prenom, item.member.nom);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? primary.withValues(alpha: 0.06) : c.secondaryBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? primary : c.borderInput),
                            ),
                            child: CheckboxListTile(
                              value: isSelected,
                              onChanged: (_) => onToggle(item.member.id),
                              activeColor: primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              secondary: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(color: c.circleColor, shape: BoxShape.circle),
                                child: Center(
                                  child: Text(initials, style: TextStyle(color: c.secondary, fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ),
                              title: Text(item.member.fullName, style: TextStyle(color: c.primaryText, fontSize: 14)),
                            ),
                          );
                        },
                      ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.secondaryText,
                    side: BorderSide(color: c.borderInput),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Retour'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: const Text('Suivant', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepConfirm extends StatelessWidget {
  final TerrainModel terrain;
  final ProduitModel? produit;
  final DateTime? date;
  final int selectedCount;
  final bool booking;
  final VoidCallback onConfirm;
  final VoidCallback onBack;

  const _StepConfirm({
    required this.terrain,
    required this.produit,
    required this.date,
    required this.selectedCount,
    required this.booking,
    required this.onConfirm,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final c = WColors.of(context);
    final dateStr = date != null ? DateFormat('dd MMMM yyyy', 'fr').format(date!) : '—';
    final timeStr = produit?.startAt != null && produit?.endAt != null
        ? '${formatHour(produit!.startAt!)} → ${formatHour(produit!.endAt!)}'
        : '—';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Confirmer la réservation', style: TextStyle(color: c.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Vérifiez les détails avant de confirmer', style: TextStyle(color: c.secondaryText, fontSize: 13)),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.secondaryBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.borderInput),
            ),
            child: Column(
              children: [
                _RecapRow(icon: Icons.sports_soccer_outlined, label: 'Sport', value: terrain.sport ?? '—'),
                Divider(color: c.alternate, height: 20),
                _RecapRow(icon: Icons.location_on_outlined, label: 'Terrain', value: terrain.nom ?? '—'),
                Divider(color: c.alternate, height: 20),
                _RecapRow(icon: Icons.confirmation_number_outlined, label: 'Créneau', value: produit?.nom ?? '—'),
                Divider(color: c.alternate, height: 20),
                _RecapRow(icon: Icons.calendar_today_outlined, label: 'Date', value: dateStr),
                Divider(color: c.alternate, height: 20),
                _RecapRow(icon: Icons.access_time_outlined, label: 'Horaire', value: timeStr),
                if (produit?.prixUnitaire != null) ...[
                  Divider(color: c.alternate, height: 20),
                  _RecapRow(
                    icon: Icons.payments_outlined,
                    label: 'Prix',
                    value: '${produit!.prixUnitaire!.toStringAsFixed(0)} DH',
                    valueColor: primary,
                  ),
                ],
                if (selectedCount > 0) ...[
                  Divider(color: c.alternate, height: 20),
                  _RecapRow(
                    icon: Icons.people_outline,
                    label: 'Invités',
                    value: '$selectedCount ami${selectedCount > 1 ? 's' : ''}',
                  ),
                ],
              ],
            ),
          ),

          const Spacer(),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.secondaryText,
                    side: BorderSide(color: c.borderInput),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Retour'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: booking ? null : onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: booking
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Réserver ✓', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecapRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _RecapRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final c = WColors.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: c.secondaryText),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: c.secondaryText, fontSize: 13)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? c.primaryText,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
