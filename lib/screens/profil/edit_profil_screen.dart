import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/supabase_constants.dart';
import '../../core/utils/helpers.dart';
import '../../models/member_model.dart';
import '../../providers/app_state.dart';

class EditProfilScreen extends StatefulWidget {
  final MemberModel? member;

  const EditProfilScreen({super.key, this.member});

  @override
  State<EditProfilScreen> createState() => _EditProfilScreenState();
}

class _EditProfilScreenState extends State<EditProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _prenomCtrl;
  late TextEditingController _nomCtrl;
  late TextEditingController _telCtrl;
  late TextEditingController _sportCtrl;
  late TextEditingController _typeCtrl;
  late TextEditingController _categorieCtrl;
  late TextEditingController _civiliteCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final m = widget.member;
    _prenomCtrl = TextEditingController(text: m?.prenom ?? '');
    _nomCtrl = TextEditingController(text: m?.nom ?? '');
    _telCtrl = TextEditingController(text: m?.telephone ?? '');
    _sportCtrl = TextEditingController(text: m?.sportPrincipal ?? '');
    _typeCtrl = TextEditingController(text: m?.type ?? '');
    _categorieCtrl = TextEditingController(text: m?.categorie ?? '');
    _civiliteCtrl = TextEditingController(text: m?.civilite ?? '');
  }

  @override
  void dispose() {
    _prenomCtrl.dispose();
    _nomCtrl.dispose();
    _telCtrl.dispose();
    _sportCtrl.dispose();
    _typeCtrl.dispose();
    _categorieCtrl.dispose();
    _civiliteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final appState = context.read<AppState>();
    final memberId = appState.currentMemberID;
    if (memberId == null) return;
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client
          .from(SupabaseConstants.memberTable)
          .update({
            'Prénom': _prenomCtrl.text.trim(),
            'Nom': _nomCtrl.text.trim(),
            'Téléphone': _telCtrl.text.trim(),
            'Sport principal': _sportCtrl.text.trim(),
            'Type': _typeCtrl.text.trim(),
            'Catégorie': _categorieCtrl.text.trim(),
            'civilité': _civiliteCtrl.text.trim(),
          })
          .eq('id', memberId);

      appState.setMember(
        id: memberId,
        name: _prenomCtrl.text.trim(),
        lastName: _nomCtrl.text.trim(),
        phone: _telCtrl.text.trim(),
        img: appState.currentMemberImg,
      );

      if (mounted) {
        showSuccessSnackbar(context, 'Profil mis à jour!');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showErrorSnackbar(context, 'Erreur: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _field(String label, TextEditingController ctrl, {
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
    required WColors c,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: c.secondaryText, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboard,
          validator: validator,
          style: TextStyle(color: c.primaryText, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: c.secondaryBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.borderInput),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.borderInput),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
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
          'Modifier le profil',
          style: TextStyle(color: c.primaryText, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _field('Prénom', _prenomCtrl, c: c, validator: (v) => v == null || v.isEmpty ? 'Requis' : null),
              const SizedBox(height: 14),
              _field('Nom', _nomCtrl, c: c, validator: (v) => v == null || v.isEmpty ? 'Requis' : null),
              const SizedBox(height: 14),
              _field('Téléphone', _telCtrl, c: c, keyboard: TextInputType.phone),
              const SizedBox(height: 14),
              _field('Sport principal', _sportCtrl, c: c),
              const SizedBox(height: 14),
              _field('Type', _typeCtrl, c: c),
              const SizedBox(height: 14),
              _field('Catégorie', _categorieCtrl, c: c),
              const SizedBox(height: 14),
              _field('Civilité', _civiliteCtrl, c: c),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Enregistrer', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
