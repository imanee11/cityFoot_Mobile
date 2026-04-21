import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/supabase_constants.dart';
import '../../models/member_model.dart';
import '../../providers/app_state.dart';
import '../../core/utils/helpers.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      final userId = res.user?.id;
      if (userId == null) throw Exception('Utilisateur introuvable');

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
      if (mounted) showErrorSnackbar(context, 'Erreur de connexion: ${e.toString()}');
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'CFS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  const Text(
                    'Welcome back',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Commençons par remplir le formulaire ci-dessous.',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  ),
                  const SizedBox(height: 32),

                  // Email
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: primaryText, fontSize: 15),
                    decoration: _fieldDeco('Email'),
                    validator: (v) => v == null || v.isEmpty ? 'Email requis' : null,
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    style: const TextStyle(color: primaryText, fontSize: 15),
                    decoration: _fieldDeco('Mot de passe').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: secondaryText,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Mot de passe requis' : null,
                  ),
                  const SizedBox(height: 28),

                  // Connexion button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
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
                              'Connexion',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Forgot password
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pushNamed('/forgot-password'),
                      child: const Text(
                        'Mot de passe oublié?',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Colors.white24, thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OU', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
                      ),
                      const Expanded(child: Divider(color: Colors.white24, thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Register link
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed('/register'),
                      child: RichText(
                        text: const TextSpan(
                          text: "Vous n'avez pas de compte? ",
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                          children: [
                            TextSpan(
                              text: 'S\'inscrire',
                              style: TextStyle(
                                color: primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
