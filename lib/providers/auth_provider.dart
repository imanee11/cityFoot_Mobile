import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'member_provider.dart';
import 'amis_provider.dart';
import 'terrain_provider.dart';
import 'match_provider.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String prenom,
    required String nom,
    required String telephone,
    String? civilite,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );
      final userId = response.user?.id;
      if (userId == null) throw Exception('Inscription échouée');

      final insertData = <String, dynamic>{
        'Prénom': prenom,
        'Nom': nom,
        'Email': email,
        'Téléphone': telephone,
        'User': userId,
      };
      if (civilite != null && civilite.isNotEmpty) {
        insertData['civilité'] = civilite;
      }

      await Supabase.instance.client.from('Member').insert(insertData);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout({
    MemberProvider? memberProvider,
    AmisProvider? amisProvider,
    TerrainProvider? terrainProvider,
    MatchProvider? matchProvider,
  }) async {
    try {
      await Supabase.instance.client.auth.signOut();
      memberProvider?.clear();
      amisProvider?.clear();
      terrainProvider?.clear();
      matchProvider?.clear();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
    notifyListeners();
  }
}
