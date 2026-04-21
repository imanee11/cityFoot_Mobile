import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/supabase_constants.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/initials_helper.dart';
import '../../models/member_model.dart';
import '../../providers/app_state.dart';
import '../../core/services/notification_service.dart';

class AjouterAmisScreen extends StatefulWidget {
  const AjouterAmisScreen({super.key});

  @override
  State<AjouterAmisScreen> createState() => _AjouterAmisScreenState();
}

class _AjouterAmisScreenState extends State<AjouterAmisScreen> {
  List<MemberModel> _nonAmis = [];
  List<MemberModel> _filtered = [];
  bool _loading = true;
  String _query = '';
  final Set<int> _sentIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchNonAmis());
  }

  Future<void> _fetchNonAmis() async {
    try {
      final currentId = context.read<AppState>().currentMemberID;
      final data = await Supabase.instance.client
          .from(SupabaseConstants.nonAmisView)
          .select();
      final list = (data as List)
          .map((e) => MemberModel.fromJson(e))
          .where((m) => m.id != currentId)
          .toList();
      if (mounted) {
        setState(() {
          _nonAmis = list;
          _filtered = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch(String query) {
    setState(() {
      _query = query;
      if (query.isEmpty) {
        _filtered = _nonAmis;
      } else {
        _filtered = _nonAmis
            .where((m) => m.fullName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _sendRequest(MemberModel member) async {
    final appState = context.read<AppState>();
    final currentMemberId = appState.currentMemberID;
    if (currentMemberId == null) return;

    setState(() => _sentIds.add(member.id));
    try {
      await Supabase.instance.client.from(SupabaseConstants.amisTable).insert({
        'Demandeur': currentMemberId,
        'Destinataire': member.id,
        'Statut': 'en attente',
      });

      setState(() {
        _nonAmis.removeWhere((m) => m.id == member.id);
        _filtered.removeWhere((m) => m.id == member.id);
      });

      await NotificationService.sendWhatsApp(
        phone: member.telephone ?? '',
        title: 'Nouvelle demande d\'ami',
        body: '${appState.currentMemberName} veut vous ajouter en ami sur OasisSports',
      );

      if (mounted) showSuccessSnackbar(context, 'Demande envoyée à ${member.fullName}');
    } catch (e) {
      setState(() => _sentIds.remove(member.id));
      if (mounted) showErrorSnackbar(context, 'Erreur: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = WColors.of(context);
    return Scaffold(
      backgroundColor: c.primaryBackground,
      appBar: AppBar(
        backgroundColor: c.secondaryBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: c.primaryText),
        title: Text(
          'Ajouter des amis',
          style: TextStyle(color: c.primaryText, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: c.secondaryBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.cardBorder),
              ),
              child: TextField(
                onChanged: _onSearch,
                style: TextStyle(color: c.primaryText, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  hintStyle: TextStyle(color: c.secondaryText),
                  prefixIcon: Icon(Icons.search, color: c.secondaryText, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: primary))
                : _filtered.isEmpty
                    ? Center(
                        child: Text(
                          _query.isEmpty ? 'Aucun membre à ajouter' : 'Aucun résultat',
                          style: TextStyle(color: c.secondaryText, fontSize: 15),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filtered.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final member = _filtered[index];
                          final initials = getInitials(member.prenom, member.nom);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: c.secondaryBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: c.cardBorder),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: c.circleColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      initials,
                                      style: TextStyle(
                                        color: c.secondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        member.fullName,
                                        style: TextStyle(
                                          color: c.primaryText,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.person_add_outlined, color: Colors.white, size: 16),
                                    onPressed: _sentIds.contains(member.id)
                                        ? null
                                        : () => _sendRequest(member),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
