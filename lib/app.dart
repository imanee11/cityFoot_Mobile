import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'providers/app_state.dart';
import 'screens/home/home_screen.dart';
import 'screens/match/mes_matchs_screen.dart';
import 'screens/match/invitations_screen.dart';
import 'screens/amis/amis_screen.dart';
import 'screens/profil/profil_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  List<Widget> get _screens => [
    HomeScreen(onNavigateToMatchs: () => setState(() => _currentIndex = 1)),
    const MesMatchsScreen(),
    const InvitationsScreen(),
    const AmisScreen(),
    const ProfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final c = WColors.of(context);
    final appState = context.watch<AppState>();
    final amisBadge = appState.demandesCount;
    final invitBadge = appState.pendingInvitationsCount;

    return Scaffold(
      backgroundColor: c.primaryBackground,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: c.secondaryBackground,
        selectedItemColor: primary,
        unselectedItemColor: c.secondaryText,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer_outlined),
            activeIcon: Icon(Icons.sports_soccer),
            label: 'Mes Mat...',
          ),
          BottomNavigationBarItem(
            icon: _badge(invitBadge, Icons.mail_outline),
            activeIcon: _badge(invitBadge, Icons.mail),
            label: 'Invitatio...',
          ),
          BottomNavigationBarItem(
            icon: _badge(amisBadge, Icons.people_outline),
            activeIcon: _badge(amisBadge, Icons.people),
            label: 'Amis',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _badge(int count, IconData icon) {
    if (count <= 0) return Icon(icon);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          right: -4,
          top: -4,
          child: Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(color: errorRed, shape: BoxShape.circle),
            child: Center(
              child: Text(
                '$count',
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
