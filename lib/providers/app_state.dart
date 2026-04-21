import 'package:flutter/material.dart';
export 'package:flutter/material.dart' show ThemeMode;

class AppState extends ChangeNotifier {
  int? _currentMemberID;
  String _currentMemberName = '';
  String _currentMemberlastName = '';
  String _currentMemberPhone = '';
  String _currentMemberImg = '';

  String _selectedTab = 'tab1';
  String _selectedTabAmis = 'amis';

  int _demandesCount = 0;
  int _mesAmisCount = 0;
  int _pendingInvitationsCount = 0;
  int _countPlayers = 0;
  int _countConfirmedPlayers = 0;
  bool _visibleTrash = false;
  int _reservationRefreshId = 0;
  ThemeMode _themeMode = ThemeMode.system;

  // Getters
  int? get currentMemberID => _currentMemberID;
  String get currentMemberName => _currentMemberName;
  String get currentMemberlastName => _currentMemberlastName;
  String get currentMemberPhone => _currentMemberPhone;
  String get currentMemberImg => _currentMemberImg;
  String get selectedTab => _selectedTab;
  String get selectedTabAmis => _selectedTabAmis;
  int get demandesCount => _demandesCount;
  int get mesAmisCount => _mesAmisCount;
  int get pendingInvitationsCount => _pendingInvitationsCount;
  int get countPlayers => _countPlayers;
  int get countConfirmedPlayers => _countConfirmedPlayers;
  bool get visibleTrash => _visibleTrash;
  bool get isLoggedIn => _currentMemberID != null;
  int get reservationRefreshId => _reservationRefreshId;
  ThemeMode get themeMode => _themeMode;

  void setMember({
    required int id,
    required String name,
    required String lastName,
    required String phone,
    required String img,
  }) {
    _currentMemberID = id;
    _currentMemberName = name;
    _currentMemberlastName = lastName;
    _currentMemberPhone = phone;
    _currentMemberImg = img;
    notifyListeners();
  }

  void clearMember() {
    _currentMemberID = null;
    _currentMemberName = '';
    _currentMemberlastName = '';
    _currentMemberPhone = '';
    _currentMemberImg = '';
    _selectedTab = 'tab1';
    _selectedTabAmis = 'amis';
    _demandesCount = 0;
    _mesAmisCount = 0;
    _pendingInvitationsCount = 0;
    _countPlayers = 0;
    _countConfirmedPlayers = 0;
    _visibleTrash = false;
    notifyListeners();
  }

  void setSelectedTab(String tab) {
    _selectedTab = tab;
    notifyListeners();
  }

  void setSelectedTabAmis(String tab) {
    _selectedTabAmis = tab;
    notifyListeners();
  }

  void setDemandesCount(int count) {
    _demandesCount = count;
    notifyListeners();
  }

  void setMesAmisCount(int count) {
    _mesAmisCount = count;
    notifyListeners();
  }

  void setPendingInvitationsCount(int count) {
    _pendingInvitationsCount = count;
    notifyListeners();
  }

  void setCountPlayers(int total, int confirmed) {
    _countPlayers = total;
    _countConfirmedPlayers = confirmed;
    notifyListeners();
  }

  void setVisibleTrash(bool v) {
    _visibleTrash = v;
    notifyListeners();
  }

  void toggleVisibleTrash() {
    _visibleTrash = !_visibleTrash;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void markReservationCreated() {
    _reservationRefreshId++;
    notifyListeners();
  }
}
