import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/supabase_constants.dart';
import '../../models/member_model.dart';
import '../../providers/app_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSession());
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    try {
      final userId = session.user.id;
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
    } catch (_) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: authBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: Text(
                    'CFS',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: primary),
          ],
        ),
      ),
    );
  }
}
