import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/supabase_constants.dart';
import 'providers/app_state.dart';
import 'app.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/reset_password_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr');
  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const OasisSportsApp(),
    ),
  );
}

class OasisSportsApp extends StatelessWidget {
  const OasisSportsApp({super.key});

  ThemeData _lightTheme() => ThemeData(
        extensions: const [WColors.light],
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        textTheme: GoogleFonts.outfitTextTheme(),
        scaffoldBackgroundColor: primaryBackground,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: secondaryBackground,
          elevation: 0,
          iconTheme: const IconThemeData(color: primaryText),
          titleTextStyle: GoogleFonts.outfit(
            color: primaryText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  ThemeData _darkTheme() => ThemeData(
        extensions: const [WColors.dark],
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        scaffoldBackgroundColor: const Color(0xFF0D173F),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF111B44),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<AppState>().themeMode;
    return MaterialApp(
      title: 'OasisSports',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/reset-password': (_) => const ResetPasswordScreen(),
        '/main': (_) => const MainScreen(),
      },
    );
  }
}
