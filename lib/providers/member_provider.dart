import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/member_model.dart';
import '../core/constants/supabase_constants.dart';

class MemberProvider extends ChangeNotifier {
  MemberModel? _currentMember;
  bool _isLoading = false;
  String? _error;

  MemberModel? get currentMember => _currentMember;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setCurrentMember(MemberModel? member) {
    _currentMember = member;
    notifyListeners();
  }

  Future<void> fetchCurrentMember() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await Supabase.instance.client
          .from(SupabaseConstants.memberTable)
          .select()
          .eq('User', user.id)
          .single();
      _currentMember = MemberModel.fromJson(data);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateMember({
    String? prenom,
    String? nom,
    String? telephone,
    String? sportPrincipal,
  }) async {
    if (_currentMember == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final updates = <String, dynamic>{};
      if (prenom != null) updates['Prénom'] = prenom;
      if (nom != null) updates['Nom'] = nom;
      if (telephone != null) updates['Téléphone'] = telephone;
      if (sportPrincipal != null) updates['Sport principal'] = sportPrincipal;

      await Supabase.instance.client
          .from(SupabaseConstants.memberTable)
          .update(updates)
          .eq('id', _currentMember!.id);

      _currentMember = _currentMember!.copyWith(
        prenom: prenom ?? _currentMember!.prenom,
        nom: nom ?? _currentMember!.nom,
        telephone: telephone ?? _currentMember!.telephone,
        sportPrincipal: sportPrincipal ?? _currentMember!.sportPrincipal,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _currentMember = null;
    _error = null;
    notifyListeners();
  }
}
