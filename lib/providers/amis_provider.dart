import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/amis_model.dart';
import '../models/member_model.dart';
import '../core/constants/supabase_constants.dart';
import '../core/services/notification_service.dart';

class AmisProvider extends ChangeNotifier {
  List<AmisModel> _mesAmis = [];
  List<AmisModel> _invitationsRecues = [];
  List<AmisModel> _invitationsEnvoyees = [];
  List<MemberModel> _nonAmis = [];
  Map<int, MemberModel> _membersCache = {};
  bool _isLoading = false;
  String? _error;

  List<AmisModel> get mesAmis => _mesAmis;
  List<AmisModel> get invitationsRecues => _invitationsRecues;
  List<AmisModel> get invitationsEnvoyees => _invitationsEnvoyees;
  List<MemberModel> get nonAmis => _nonAmis;
  Map<int, MemberModel> get membersCache => _membersCache;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // MesAmis view already filters to accepté and scopes to current user — query directly.
  Future<void> fetchMesAmis(int currentMemberId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await Supabase.instance.client
          .from(SupabaseConstants.mesAmisView)
          .select();

      _mesAmis = (data as List).map((e) => AmisModel.fromJson(e)).toList();

      // Pre-cache the other person's Member info using AmiId from the view.
      for (final ami in _mesAmis) {
        final otherId = ami.amiId;
        if (otherId != null && !_membersCache.containsKey(otherId)) {
          await _fetchAndCacheMember(otherId);
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchAndCacheMember(int memberId) async {
    try {
      final data = await Supabase.instance.client
          .from(SupabaseConstants.memberTable)
          .select()
          .eq('id', memberId)
          .single();
      _membersCache[memberId] = MemberModel.fromJson(data);
    } catch (e) {
      debugPrint('Error fetching member $memberId: $e');
    }
  }

  Future<MemberModel?> getMemberById(int id) async {
    if (_membersCache.containsKey(id)) return _membersCache[id];
    await _fetchAndCacheMember(id);
    return _membersCache[id];
  }

  // Uses AmiId from MesAmis view — always the other person.
  MemberModel? getAmiMember(AmisModel ami, int currentMemberId) {
    final otherId = ami.amiId ??
        (ami.demandeur == currentMemberId ? ami.destinataire : ami.demandeur);
    return _membersCache[otherId];
  }

  Future<void> fetchInvitationsRecues(int currentMemberId) async {
    try {
      final data = await Supabase.instance.client
          .from(SupabaseConstants.amisTable)
          .select()
          .eq('Destinataire', currentMemberId)
          .eq('Statut', 'en attente');
      _invitationsRecues =
          (data as List).map((e) => AmisModel.fromJson(e)).toList();

      for (final inv in _invitationsRecues) {
        if (!_membersCache.containsKey(inv.demandeur)) {
          await _fetchAndCacheMember(inv.demandeur);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('fetchInvitationsRecues error: $e');
    }
  }

  Future<void> fetchInvitationsEnvoyees(int currentMemberId) async {
    try {
      final data = await Supabase.instance.client
          .from(SupabaseConstants.amisTable)
          .select()
          .eq('Demandeur', currentMemberId)
          .eq('Statut', 'en attente');
      _invitationsEnvoyees =
          (data as List).map((e) => AmisModel.fromJson(e)).toList();

      for (final inv in _invitationsEnvoyees) {
        if (!_membersCache.containsKey(inv.destinataire)) {
          await _fetchAndCacheMember(inv.destinataire);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('fetchInvitationsEnvoyees error: $e');
    }
  }

  // NonAmis view already excludes current user and all existing relations.
  Future<void> fetchNonAmis() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await Supabase.instance.client
          .from(SupabaseConstants.nonAmisView)
          .select();
      _nonAmis =
          (data as List).map((e) => MemberModel.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendFriendRequest(
    int currentMemberId,
    String currentMemberPrenom,
    int destinataireId,
    String destinatairePhone,
  ) async {
    try {
      await Supabase.instance.client.from(SupabaseConstants.amisTable).insert({
        'Demandeur': currentMemberId,
        'Destinataire': destinataireId,
        'Statut': 'en attente',
      });
      _nonAmis.removeWhere((m) => m.id == destinataireId);
      notifyListeners();

      await NotificationService.sendWhatsAppNotification(
        destinatairePhone,
        "Nouvelle demande d'ami",
        '$currentMemberPrenom veut vous ajouter en ami sur OasisSports',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> acceptFriendRequest(
    int amisId,
    int demandeurId,
    String demandeurPhone,
    String currentMemberPrenom,
    int currentMemberId,
  ) async {
    try {
      await Supabase.instance.client
          .from(SupabaseConstants.amisTable)
          .update({'Statut': 'accepté'})
          .eq('id', amisId);
      _invitationsRecues.removeWhere((a) => a.id == amisId);
      notifyListeners();

      await fetchMesAmis(currentMemberId);

      await NotificationService.sendWhatsAppNotification(
        demandeurPhone,
        'Demande acceptée',
        "$currentMemberPrenom a accepté votre demande d'ami",
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refuseFriendRequest(int amisId) async {
    try {
      await Supabase.instance.client
          .from(SupabaseConstants.amisTable)
          .update({'Statut': 'refusé'})
          .eq('id', amisId);
      _invitationsRecues.removeWhere((a) => a.id == amisId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelFriendRequest(int amisId) async {
    try {
      await Supabase.instance.client
          .from(SupabaseConstants.amisTable)
          .delete()
          .eq('id', amisId);
      _invitationsEnvoyees.removeWhere((a) => a.id == amisId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteFriend(int amisId) async {
    try {
      await Supabase.instance.client
          .from(SupabaseConstants.amisTable)
          .delete()
          .eq('id', amisId);
      _mesAmis.removeWhere((a) => a.id == amisId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  void clear() {
    _mesAmis = [];
    _invitationsRecues = [];
    _invitationsEnvoyees = [];
    _nonAmis = [];
    _membersCache = {};
    _error = null;
    notifyListeners();
  }
}
