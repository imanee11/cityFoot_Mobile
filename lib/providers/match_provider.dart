import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reservation_model.dart';
import '../models/invitation_model.dart';
import '../models/terrain_model.dart';
import '../models/member_model.dart';
import '../core/constants/supabase_constants.dart';
import '../core/services/notification_service.dart';

class MatchProvider extends ChangeNotifier {
  List<ReservationModel> _mesReservations = [];
  List<InvitationModel> _mesInvitations = [];
  List<InvitationModel> _allInvitations = [];
  bool _isLoading = false;
  String? _error;
  String? _lastReservationId;

  List<ReservationModel> get mesMatchs => _mesReservations;
  List<InvitationModel> get mesInvitations => _mesInvitations;
  List<InvitationModel> get allInvitations => _allInvitations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get lastReservationId => _lastReservationId;

  List<ReservationModel> get upcomingReservations {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _mesReservations.where((r) {
      if (r.dateDeResa == null) return false;
      final d = DateTime(
          r.dateDeResa!.year, r.dateDeResa!.month, r.dateDeResa!.day);
      return !d.isBefore(today);
    }).toList()
      ..sort((a, b) => (a.dateDeResa ?? DateTime.now())
          .compareTo(b.dateDeResa ?? DateTime.now()));
  }

  List<ReservationModel> get pastReservations {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _mesReservations.where((r) {
      if (r.dateDeResa == null) return true;
      final d = DateTime(
          r.dateDeResa!.year, r.dateDeResa!.month, r.dateDeResa!.day);
      return d.isBefore(today);
    }).toList()
      ..sort((a, b) => (b.dateDeResa ?? DateTime.now())
          .compareTo(a.dateDeResa ?? DateTime.now()));
  }

  // Query Réservation where Client OR Capitaine = currentMember.id
  Future<void> fetchMesMatchs(int currentMemberId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await Supabase.instance.client
          .from(SupabaseConstants.reservationTable)
          .select()
          .or('Client.eq.$currentMemberId,Capitaine.eq.$currentMemberId');
      _mesReservations =
          (data as List).map((e) => ReservationModel.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Query Invitation where Invité = currentMember.id AND Statut = 'en attente'
  Future<void> fetchMesInvitations(int currentMemberId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await Supabase.instance.client
          .from(SupabaseConstants.invitationTable)
          .select()
          .eq('Invité', currentMemberId)
          .eq('Statut', 'en attente');
      _mesInvitations =
          (data as List).map((e) => InvitationModel.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Query ALL invitations where Invité = currentMember.id (all statuses)
  Future<void> fetchAllInvitations(int currentMemberId) async {
    try {
      final data = await Supabase.instance.client
          .from(SupabaseConstants.invitationTable)
          .select()
          .eq('Invité', currentMemberId)
          .order('created_at', ascending: false);
      _allInvitations =
          (data as List).map((e) => InvitationModel.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('fetchAllInvitations error: $e');
    }
  }

  Future<void> reserverTerrain({
    required TerrainModel terrain,
    required DateTime date,
    required double heureDebut,
    required double duree,
    required List<MemberModel> invites,
    required int currentMemberId,
    required String currentMemberPrenom,
    int? produitId,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final heureFin = heureDebut + duree;
      final insertMap = <String, dynamic>{
        'Terrain': terrain.id,
        'Sport': terrain.sport,
        'Client': currentMemberId,
        'Capitaine': currentMemberId,
        'Joueurs': currentMemberId,
        'Date de résa': date.toIso8601String(),
        'Heure_début': heureDebut,
        'Heure_fin': heureFin,
        'Durée': duree,
        'Privé_Public': 'Privé',
        'Présence': 'Valide',
        'Titre': 'Match ${terrain.nom ?? ''}',
      };
      if (produitId != null) {
        insertMap['Produit'] = produitId;
      }

      final reservationData = await Supabase.instance.client
          .from(SupabaseConstants.reservationTable)
          .insert(insertMap)
          .select()
          .single();

      final newReservationId = reservationData['id'] as String;
      _lastReservationId = newReservationId;

      for (final invite in invites) {
        try {
          await Supabase.instance.client
              .from(SupabaseConstants.invitationTable)
              .insert({
            'Réservation': newReservationId,
            'Invité': invite.id,
            'Inviteur': currentMemberId,
            'Statut': 'en attente',
          });
          if (invite.telephone != null && invite.telephone!.isNotEmpty) {
            await NotificationService.sendWhatsAppNotification(
              invite.telephone!,
              'Invitation à un match',
              '$currentMemberPrenom vous invite à un match de ${terrain.sport ?? 'sport'} sur OasisSports',
            );
          }
        } catch (e) {
          debugPrint('Error inviting member ${invite.id}: $e');
        }
      }

      await fetchMesMatchs(currentMemberId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> accepterInvitation(
      int invitationId, int currentMemberId) async {
    try {
      await Supabase.instance.client
          .from(SupabaseConstants.invitationTable)
          .update({'Statut': 'accepté'}).eq('id', invitationId);
      _mesInvitations.removeWhere((i) => i.id == invitationId);
      // Update allInvitations status
      final idx = _allInvitations.indexWhere((i) => i.id == invitationId);
      if (idx != -1) {
        final old = _allInvitations[idx];
        _allInvitations[idx] = InvitationModel(
          id: old.id,
          createdAt: old.createdAt,
          reservation: old.reservation,
          invite: old.invite,
          inviteur: old.inviteur,
          statut: 'accepté',
        );
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refuserInvitation(int invitationId) async {
    try {
      await Supabase.instance.client
          .from(SupabaseConstants.invitationTable)
          .update({'Statut': 'refusé'}).eq('id', invitationId);
      _mesInvitations.removeWhere((i) => i.id == invitationId);
      // Update allInvitations status
      final idx = _allInvitations.indexWhere((i) => i.id == invitationId);
      if (idx != -1) {
        final old = _allInvitations[idx];
        _allInvitations[idx] = InvitationModel(
          id: old.id,
          createdAt: old.createdAt,
          reservation: old.reservation,
          invite: old.invite,
          inviteur: old.inviteur,
          statut: 'refusé',
        );
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  void clear() {
    _mesReservations = [];
    _mesInvitations = [];
    _allInvitations = [];
    _lastReservationId = null;
    _error = null;
    notifyListeners();
  }
}
