import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/supabase_constants.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/initials_helper.dart';
import '../../models/member_model.dart';
import '../../providers/app_state.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  MemberModel? _member;
  bool _loading = true;
  bool _saving = false;
  int _matchsJoues = 0;
  int _amisCount = 0;

  late TextEditingController _prenomCtrl;
  late TextEditingController _nomCtrl;
  late TextEditingController _telCtrl;

  @override
  void initState() {
    super.initState();
    _prenomCtrl = TextEditingController();
    _nomCtrl = TextEditingController();
    _telCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAll());
  }

  @override
  void dispose() {
    _prenomCtrl.dispose();
    _nomCtrl.dispose();
    _telCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    final memberId = context.read<AppState>().currentMemberID;
    if (memberId == null) return;
    try {
      final results = await Future.wait<dynamic>([
        Supabase.instance.client
            .from(SupabaseConstants.memberTable)
            .select()
            .eq('id', memberId)
            .single(),
        Supabase.instance.client
            .from(SupabaseConstants.reservationTable)
            .select('id')
            .eq('Client', memberId)
            .lt('match_datetime', DateTime.now().toUtc().toIso8601String()),
        Supabase.instance.client
            .from(SupabaseConstants.mesAmisView)
            .select('id'),
      ]);
      if (mounted) {
        final m = MemberModel.fromJson(results[0]);
        setState(() {
          _member = m;
          _loading = false;
          _prenomCtrl.text = m.prenom ?? '';
          _nomCtrl.text = m.nom ?? '';
          _telCtrl.text = m.telephone ?? '';
          _matchsJoues = (results[1] as List).length;
          _amisCount = (results[2] as List).length;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final appState = context.read<AppState>();
    final memberId = appState.currentMemberID;
    if (memberId == null) return;
    setState(() => _saving = true);
    try {
      await Supabase.instance.client
          .from(SupabaseConstants.memberTable)
          .update({
            'Prénom': _prenomCtrl.text.trim(),
            'Nom': _nomCtrl.text.trim(),
            'Téléphone': _telCtrl.text.trim(),
          })
          .eq('id', memberId);

      appState.setMember(
        id: memberId,
        name: _prenomCtrl.text.trim(),
        lastName: _nomCtrl.text.trim(),
        phone: _telCtrl.text.trim(),
        img: appState.currentMemberImg,
      );

      if (mounted) showSuccessSnackbar(context, 'Profil mis à jour!');
    } catch (e) {
      if (mounted) showErrorSnackbar(context, 'Erreur: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Se déconnecter?',
      body: 'Vous serez redirigé vers la page de connexion.',
      confirmLabel: 'Déconnecter',
      confirmColor: errorRed,
    );
    if (!confirmed) return;
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      context.read<AppState>().clearMember();
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  InputDecoration _fieldDeco(WColors c) => InputDecoration(
        labelStyle: const TextStyle(fontSize: 12),
        filled: true,
        fillColor: c.secondaryBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final c = WColors.of(context);
    final appState = context.watch<AppState>();
    final initials = getInitials(appState.currentMemberName, appState.currentMemberlastName);
    final fullName = '${appState.currentMemberName} ${appState.currentMemberlastName}'.trim();
    final currentMode = appState.themeMode;

    return Scaffold(
      backgroundColor: c.primaryBackground,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [primary, Color(0xFF14225D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(fullName, style: TextStyle(color: c.primaryText, fontSize: 20, fontWeight: FontWeight.bold)),
                    if (_member?.email != null) ...[
                      const SizedBox(height: 4),
                      Text(_member!.email!, style: TextStyle(color: c.secondaryText, fontSize: 13)),
                    ],
                    const SizedBox(height: 20),

                    // Stats
                    Row(
                      children: [
                        Expanded(child: _StatCard(icon: Icons.calendar_month_outlined, count: _matchsJoues, label: 'Matchs joués', c: c)),
                        const SizedBox(width: 12),
                        Expanded(child: _StatCard(icon: Icons.people_outline, count: _amisCount, label: 'Amis', c: c)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Mes informations
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Mes informations', style: TextStyle(color: c.primaryText, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Prénom', style: TextStyle(color: c.secondaryText, fontSize: 12)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _prenomCtrl,
                                style: TextStyle(color: c.primaryText, fontSize: 14),
                                decoration: _fieldDeco(c),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Nom', style: TextStyle(color: c.secondaryText, fontSize: 12)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _nomCtrl,
                                style: TextStyle(color: c.primaryText, fontSize: 14),
                                decoration: _fieldDeco(c),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Téléphone', style: TextStyle(color: c.secondaryText, fontSize: 12)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _telCtrl,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: c.primaryText, fontSize: 14),
                      decoration: _fieldDeco(c),
                    ),
                    const SizedBox(height: 12),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Email', style: TextStyle(color: c.secondaryText, fontSize: 12)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: c.secondaryBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.cardBorder),
                      ),
                      child: Text(_member?.email ?? '', style: TextStyle(color: c.primaryText, fontSize: 14)),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.save_outlined, size: 20),
                        label: const Text('Enregistrer', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Apparence
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Apparence', style: TextStyle(color: c.primaryText, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        _ThemeOption(
                          icon: Icons.wb_sunny_outlined,
                          label: 'Clair',
                          active: currentMode == ThemeMode.light,
                          c: c,
                          onTap: () => appState.setThemeMode(ThemeMode.light),
                        ),
                        const SizedBox(width: 10),
                        _ThemeOption(
                          icon: Icons.nightlight_round,
                          label: 'Sombre',
                          active: currentMode == ThemeMode.dark,
                          c: c,
                          onTap: () => appState.setThemeMode(ThemeMode.dark),
                        ),
                        const SizedBox(width: 10),
                        _ThemeOption(
                          icon: Icons.desktop_windows_outlined,
                          label: 'Système',
                          active: currentMode == ThemeMode.system,
                          c: c,
                          onTap: () => appState.setThemeMode(ThemeMode.system),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, color: errorRed, size: 18),
                        label: const Text('Se déconnecter', style: TextStyle(color: errorRed, fontWeight: FontWeight.w600, fontSize: 15)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: errorRed, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final WColors c;

  const _StatCard({required this.icon, required this.count, required this.label, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: c.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.cardBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Icon(icon, color: primary, size: 26),
          const SizedBox(height: 8),
          Text('$count', style: TextStyle(color: c.primaryText, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: c.secondaryText, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final WColors c;
  final VoidCallback onTap;

  const _ThemeOption({required this.icon, required this.label, required this.active, required this.c, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active ? primary : c.secondaryBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: active ? Colors.transparent : c.cardBorder),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              Icon(icon, color: active ? Colors.white : c.secondaryText, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : c.secondaryText,
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
