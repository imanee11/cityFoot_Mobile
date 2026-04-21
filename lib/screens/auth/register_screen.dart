import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/supabase_constants.dart';
import '../../models/member_model.dart';
import '../../providers/app_state.dart';
import '../../core/utils/helpers.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _civilite;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  static const List<String> _civilites = ['M.', 'Mme', 'Autre'];

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passCtrl.text != _confirmCtrl.text) {
      showErrorSnackbar(context, 'Les mots de passe ne correspondent pas');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      final userId = res.user?.id;
      if (userId == null) throw Exception('Erreur lors de la création du compte');

      await Supabase.instance.client.from(SupabaseConstants.memberTable).insert({
        'Prénom': _prenomCtrl.text.trim(),
        'Nom': _nomCtrl.text.trim(),
        'Email': _emailCtrl.text.trim(),
        'Téléphone': _telCtrl.text.trim(),
        'civilité': _civilite ?? '',
        'User': userId,
      });

      final data = await Supabase.instance.client
          .from(SupabaseConstants.memberTable)
          .select()
          .eq('User', userId)
          .single();
      final member = MemberModel.fromJson(data);

      if (!mounted) return;
      context.read<AppState>().setMember(
            id: member.id,
            name: member.prenom ?? '',
            lastName: member.nom ?? '',
            phone: member.telephone ?? '',
            img: member.img ?? '',
          );
      Navigator.of(context).pushReplacementNamed('/main');
    } catch (e) {
      if (mounted) showErrorSnackbar(context, "Erreur d'inscription: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _fieldDeco(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        filled: true,
        fillColor: primaryBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBackground, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBackground, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: authBackground,
      appBar: AppBar(
        backgroundColor: authBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 90,
                    height: 90,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text(
                          'CFS',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Créer un compte',
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Remplissez le formulaire pour créer votre compte.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                ),
                const SizedBox(height: 28),

                // Civilité dropdown
                DropdownButtonFormField<String>(
                  initialValue: _civilite,
                  items: _civilites
                      .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: primaryText))))
                      .toList(),
                  onChanged: (v) => setState(() => _civilite = v),
                  decoration: _fieldDeco('Civilité'),
                  dropdownColor: primaryBackground,
                  style: const TextStyle(color: primaryText, fontSize: 15),
                ),
                const SizedBox(height: 16),

                // Nom
                TextFormField(
                  controller: _nomCtrl,
                  style: const TextStyle(color: primaryText, fontSize: 15),
                  decoration: _fieldDeco('Nom'),
                  validator: (v) => v == null || v.isEmpty ? 'Nom requis' : null,
                ),
                const SizedBox(height: 16),

                // Prénom
                TextFormField(
                  controller: _prenomCtrl,
                  style: const TextStyle(color: primaryText, fontSize: 15),
                  decoration: _fieldDeco('Prénom'),
                  validator: (v) => v == null || v.isEmpty ? 'Prénom requis' : null,
                ),
                const SizedBox(height: 16),

                // Téléphone
                TextFormField(
                  controller: _telCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: primaryText, fontSize: 15),
                  decoration: _fieldDeco('Téléphone'),
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: primaryText, fontSize: 15),
                  decoration: _fieldDeco('Email'),
                  validator: (v) => v == null || v.isEmpty ? 'Email requis' : null,
                ),
                const SizedBox(height: 16),

                // Mot de passe
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  style: const TextStyle(color: primaryText, fontSize: 15),
                  decoration: _fieldDeco('Mot de passe').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: secondaryText,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: (v) => v == null || v.length < 6 ? 'Minimum 6 caractères' : null,
                ),
                const SizedBox(height: 16),

                // Confirmer mot de passe
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  style: const TextStyle(color: primaryText, fontSize: 15),
                  decoration: _fieldDeco('Confirmer mot de passe').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: secondaryText,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Confirmation requise' : null,
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Créer un compte',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: RichText(
                      text: const TextSpan(
                        text: 'Vous avez déjà un compte? ',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                        children: [
                          TextSpan(
                            text: 'Se connecter',
                            style: TextStyle(color: primary, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
