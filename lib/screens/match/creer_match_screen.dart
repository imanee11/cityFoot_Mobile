import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/supabase_constants.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/initials_helper.dart';
import '../../models/produit_model.dart';
import '../../models/terrain_model.dart';
import '../../models/member_model.dart';
import '../../providers/app_state.dart';

class CreerMatchScreen extends StatefulWidget {
  const CreerMatchScreen({super.key});

  @override
  State<CreerMatchScreen> createState() => _CreerMatchScreenState();
}

class _CreerMatchScreenState extends State<CreerMatchScreen> {
  int _step = 0;

  String? _selectedSport;
  DateTime? _selectedDate;
  double? _selectedHeure;
  TerrainModel? _selectedTerrain;
  ProduitModel? _selectedProduit;
  String? _newReservationId;

  Future<Set<double>>? _bookedHoursFuture;

  List<MemberModel> _amis = [];
  bool _amisLoaded = false;
  final Set<int> _selectedAmiIds = {};
  String _inviteQuery = '';
  int _stepDirection = 1;

  static const List<String> _stepNames = [
    'Sport', 'Jour', 'Heure', 'Terrain', 'Confirmer', 'Inviter',
  ];

  static const List<Map<String, dynamic>> _sports = [
    {'name': 'Football', 'emoji': '⚽', 'detail': '5v5 ou 7v7'},
    {'name': 'Padel', 'emoji': '🎾', 'detail': '2v2'},
    {'name': 'Basket', 'emoji': '🏀', 'detail': '5v5'},
  ];

  void _next() { if (_step < _stepNames.length - 1) setState(() => _step++); }
  void _prev() { if (_step > 0) setState(() => _step--); }

  String _formatDate(DateTime dt) {
    const wd = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    const mo = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${wd[dt.weekday - 1]} ${dt.day} ${mo[dt.month - 1]}';
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static final List<double> _allHours = List.generate(18, (i) => (8 + i).toDouble());

  bool _isHourPast(double h) {
    if (_selectedDate == null) return false;
    if (!_isSameDay(_selectedDate!, DateTime.now())) return false;
    return h <= DateTime.now().hour;
  }

  String _sportPattern(String sport) {
    switch (sport.toLowerCase()) {
      case 'football': return '%foot%';
      case 'padel':    return '%padel%';
      case 'basket':   return '%basket%';
      default:         return '%${sport.toLowerCase()}%';
    }
  }

  String _sportKey(String sport) {
    switch (sport.toLowerCase()) {
      case 'football': return 'foot';
      case 'padel':    return 'padel';
      case 'basket':   return 'basket';
      default:         return sport.toLowerCase();
    }
  }

  double get _duree => _selectedSport?.toLowerCase() == 'padel' ? 1.5 : 1.0;

  Future<Set<double>> _computeBookedHours() async {
    if (_selectedSport == null || _selectedDate == null) return {};
    try {
      final terrainRes = await Supabase.instance.client
          .from(SupabaseConstants.terrainTable)
          .select('id')
          .ilike('Type de sport', _sportPattern(_selectedSport!));
      final allIds = (terrainRes as List)
          .map((e) => e['id'] as String?)
          .whereType<String>()
          .toSet();
      if (allIds.isEmpty) return {};

      final dayStart = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 0, 0, 0).toIso8601String();
      final dayEnd   = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 23, 59, 59).toIso8601String();

      final resRes = await Supabase.instance.client
          .from(SupabaseConstants.reservationTable)
          .select('Terrain, Heure_début, Heure_fin')
          .inFilter('Terrain', allIds.toList())
          .gte('Date de résa', dayStart)
          .lte('Date de résa', dayEnd);

      final reservations = resRes as List;
      final duree = _duree;

      final Set<double> fullyBooked = {};
      for (final h in _allHours) {
        final blockedIds = reservations
            .where((row) {
              final start = (row['Heure_début'] as num?)?.toDouble();
              final end   = (row['Heure_fin']   as num?)?.toDouble();
              final t     = row['Terrain'] as String?;
              if (start == null || end == null || t == null) return false;
              return start < h + duree && end > h;
            })
            .map((row) => row['Terrain'] as String)
            .toSet();
        if (blockedIds.length >= allIds.length) fullyBooked.add(h);
      }

      return fullyBooked;
    } catch (_) {
      return {};
    }
  }

  Future<List<TerrainModel>> _fetchAvailableTerrains() async {
    if (_selectedSport == null || _selectedDate == null || _selectedHeure == null) {
      return [];
    }

    final allTerrainsResponse = await Supabase.instance.client
        .from(SupabaseConstants.terrainTable)
        .select()
        .ilike('Type de sport', _sportPattern(_selectedSport!));

    final List<TerrainModel> allTerrains = (allTerrainsResponse as List)
        .map((e) => TerrainModel.fromJson(e))
        .toList();

    if (allTerrains.isEmpty) return [];

    final String dayStart = DateTime(
      _selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 0, 0, 0,
    ).toIso8601String();
    final String dayEnd = DateTime(
      _selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 23, 59, 59,
    ).toIso8601String();

    final bookedResponse = await Supabase.instance.client
        .from(SupabaseConstants.reservationTable)
        .select('Terrain')
        .lt('Heure_début', _selectedHeure! + _duree)
        .gt('Heure_fin', _selectedHeure!)
        .gte('Date de résa', dayStart)
        .lte('Date de résa', dayEnd);

    final List<String> bookedIds = (bookedResponse as List)
        .map((row) => row['Terrain'] as String?)
        .whereType<String>()
        .toList();

    return allTerrains.where((t) => !bookedIds.contains(t.id)).toList();
  }

  Future<List<ProduitModel>> _fetchProduits() async {
    if (_selectedTerrain == null || _selectedSport == null || _selectedHeure == null) return [];
    try {
      final data = await Supabase.instance.client
          .from(SupabaseConstants.produitTable)
          .select()
          .eq('Terrain', _selectedTerrain!.id)
          .ilike('Sport', _sportPattern(_selectedSport!));

      final all = (data as List).map((e) => ProduitModel.fromJson(e)).toList();

      final dayNum = _selectedDate != null
          ? (_selectedDate!.weekday == 7 ? 0 : _selectedDate!.weekday)
          : null;

      final dayFiltered = dayNum == null
          ? all
          : all.where((p) {
              if (p.days == null || p.days!.isEmpty) return true;
              final available = p.days!
                  .split(',')
                  .map((d) => int.tryParse(d.trim()))
                  .whereType<int>()
                  .toSet();
              return available.contains(dayNum);
            }).toList();

      final candidates = dayFiltered.isNotEmpty ? dayFiltered : all;

      final filtered = candidates.where((p) {
        if (p.startAt == null || p.endAt == null) return true;
        return _selectedHeure! >= p.startAt! && _selectedHeure! < p.endAt!;
      }).toList();

      return filtered.isNotEmpty ? filtered : candidates;
    } catch (_) {
      return [];
    }
  }

  Future<void> _createReservation() async {
    final appState = context.read<AppState>();
    final memberId = appState.currentMemberID;
    if (memberId == null || _selectedTerrain == null || _selectedDate == null ||
        _selectedHeure == null || _selectedProduit == null) {
      throw Exception('Informations manquantes');
    }

    final prenom = appState.currentMemberName;
    final nom = appState.currentMemberlastName;
    final titre = '$prenom $nom'.trim();
    final sportKey = _sportKey(_selectedSport!);
    final duree = _duree;
    final hour = _selectedHeure!.floor() % 24;
    final matchDatetime = DateTime(
      _selectedDate!.year, _selectedDate!.month, _selectedDate!.day, hour,
    ).toUtc();

    final resResult = await Supabase.instance.client
        .from(SupabaseConstants.reservationTable)
        .insert({
          'Titre': titre,
          'Type de réservation': 'Réservation',
          'Std / avancée': 'Standard',
          'catégorie': 'FootOutDoor',
          'Sport': sportKey,
          'Terrain': _selectedTerrain!.id,
          'Client': memberId,
          'Capitaine': memberId,
          'Prénom': prenom,
          'Nom': nom,
          'Durée': duree,
          'Heure_début': _selectedHeure,
          'Heure_fin': _selectedHeure! + duree,
          'Date de résa': matchDatetime.toIso8601String(),
          'match_datetime': matchDatetime.toIso8601String(),
          'Produit': _selectedProduit!.id,
          'Payé / Non payé': false,
        })
        .select('id')
        .single();

    _newReservationId = resResult['id'] as String;

    final opResult = await Supabase.instance.client
        .from(SupabaseConstants.operationTable)
        .insert({
          'Client': memberId,
          'Réservation': _newReservationId,
          'Produit': _selectedProduit!.id,
          'Montant à payer': _selectedProduit!.prixUnitaire,
          'Reste à payer': _selectedProduit!.prixUnitaire,
          "Type d'opération": 'Réservation',
          'Date de résa': matchDatetime.toIso8601String(),
          'Payé / Non payé': false,
        })
        .select('id')
        .single();

    final opId = opResult['id'] as int;
    await Supabase.instance.client
        .from(SupabaseConstants.reservationTable)
        .update({'Opération': opId})
        .eq('id', _newReservationId!);
  }

  Future<void> _loadAmis() async {
    if (_amisLoaded) return;
    final memberId = context.read<AppState>().currentMemberID;
    if (memberId == null) return;
    try {
      final data = await Supabase.instance.client
          .from(SupabaseConstants.mesAmisView)
          .select();
      final amiIds = (data as List)
          .map((e) => e['AmiId'] as int?)
          .whereType<int>()
          .toList();
      if (amiIds.isEmpty) {
        if (mounted) setState(() { _amisLoaded = true; _amis = []; });
        return;
      }
      final members = await Supabase.instance.client
          .from(SupabaseConstants.memberTable)
          .select()
          .inFilter('id', amiIds);
      if (mounted) {
        setState(() {
          _amis = (members as List).map((e) => MemberModel.fromJson(e)).toList();
          _amisLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _amisLoaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = WColors.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: c.primaryBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: c.borderInput,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: c.primaryText, size: 20),
                  onPressed: () {
                    if (_step > 0) { _prev(); }
                    else { Navigator.of(context).pop(); }
                  },
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Créer un match', style: TextStyle(color: c.primaryText, fontSize: 17, fontWeight: FontWeight.bold)),
                      Text(_stepNames[_step], style: TextStyle(color: c.secondaryText, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Progress bar
          LinearProgressIndicator(
            value: (_step + 1) / _stepNames.length,
            backgroundColor: c.alternate,
            valueColor: const AlwaysStoppedAnimation<Color>(primary),
            minHeight: 4,
          ),
          // Step content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              layoutBuilder: (currentChild, previousChildren) => Stack(
                alignment: Alignment.topCenter,
                children: [
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              ),
              transitionBuilder: (child, animation) {
                final slide = Tween<Offset>(
                  begin: Offset(0.08 * _stepDirection, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
                return FadeTransition(
                  opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  child: SlideTransition(position: slide, child: child),
                );
              },
              child: KeyedSubtree(key: ValueKey(_step), child: _buildStep()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _buildSportStep();
      case 1: return _buildJourStep();
      case 2: return _buildHeureStep();
      case 3: return _buildTerrainStep();
      case 4: return _buildConfirmerStep();
      case 5: return _buildInviterStep();
      default: return const SizedBox();
    }
  }

  Widget _buildSportStep() {
    final c = WColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quel sport ?', style: TextStyle(color: c.primaryText, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Choisissez votre sport favori', style: TextStyle(color: c.secondaryText, fontSize: 14)),
          const SizedBox(height: 24),
          ..._sports.map((s) {
            final isSelected = _selectedSport == s['name'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSport = s['name'] as String;
                  _selectedTerrain = null;
                  _selectedProduit = null;
                  _bookedHoursFuture = null;
                });
                Future.delayed(const Duration(milliseconds: 150), _next);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isSelected ? primary : c.secondaryBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSelected ? Colors.transparent : c.cardBorder),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Text(s['emoji'] as String, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s['name'] as String, style: TextStyle(color: isSelected ? Colors.white : c.primaryText, fontWeight: FontWeight.bold, fontSize: 17)),
                          Text(s['detail'] as String, style: TextStyle(color: isSelected ? Colors.white70 : c.secondaryText, fontSize: 13)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: isSelected ? Colors.white : c.secondaryText, size: 16),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildJourStep() {
    final c = WColors.of(context);
    final now = DateTime.now();
    final days = List.generate(10, (i) => DateTime(now.year, now.month, now.day + i));
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quel jour ?', style: TextStyle(color: c.primaryText, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Choisissez la date de votre match', style: TextStyle(color: c.secondaryText, fontSize: 14)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: days.asMap().entries.map((entry) {
              final i = entry.key;
              final day = entry.value;
              final isSelected = _selectedDate != null && _isSameDay(_selectedDate!, day);
              String label;
              if (i == 0) {
                label = "Aujourd'hui";
              } else if (i == 1) {
                label = 'Demain';
              } else {
                const wd = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
                label = '${wd[day.weekday - 1]} ${day.day}';
              }
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = day;
                    _selectedHeure = null;
                    _bookedHoursFuture = _computeBookedHours();
                  });
                  Future.delayed(const Duration(milliseconds: 150), _next);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  decoration: BoxDecoration(
                    color: isSelected ? primary : c.secondaryBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? Colors.transparent : c.cardBorder),
                  ),
                  child: Text(label, style: TextStyle(color: isSelected ? Colors.white : c.primaryText, fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeureStep() {
    final c = WColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quelle heure ?', style: TextStyle(color: c.primaryText, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Expanded(
            child: FutureBuilder<Set<double>>(
              future: _bookedHoursFuture,
              builder: (context, snapshot) {
                final bookedHours = snapshot.data ?? {};
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisExtent: 48,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _allHours.length,
                  itemBuilder: (context, index) {
                    final h = _allHours[index];
                    final isSelected = _selectedHeure == h;
                    final isPast = _isHourPast(h);
                    final isFull = bookedHours.contains(h);
                    final isDisabled = isPast || isFull;
                    return GestureDetector(
                      onTap: isDisabled
                          ? null
                          : () {
                              setState(() {
                                _selectedHeure = h;
                                _selectedTerrain = null;
                                _selectedProduit = null;
                              });
                              Future.delayed(const Duration(milliseconds: 150), _next);
                            },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primary
                              : isDisabled
                                  ? c.secondaryBackground.withValues(alpha: 0.5)
                                  : c.secondaryBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? Colors.transparent : c.cardBorder),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              formatHour(h),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : isDisabled
                                        ? c.secondaryText.withValues(alpha: 0.4)
                                        : c.primaryText,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            if (isFull && !isPast)
                              Text(
                                'Complet',
                                style: TextStyle(
                                  color: errorRed.withValues(alpha: 0.8),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _terrainDateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return "Aujourd'hui";
    if (d == today.add(const Duration(days: 1))) return 'Demain';
    const wd = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return '${wd[dt.weekday - 1]} ${dt.day}';
  }

  Widget _buildTerrainStep() {
    final c = WColors.of(context);
    return FutureBuilder<List<TerrainModel>>(
      key: ValueKey('${_selectedSport}_${_selectedDate?.toIso8601String()}_$_selectedHeure'),
      future: _fetchAvailableTerrains(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primary));
        }
        final terrains = snapshot.data ?? [];

        if (terrains.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_busy_outlined, size: 56, color: c.secondaryText),
                  const SizedBox(height: 16),
                  Text('Aucun terrain disponible', style: TextStyle(color: c.primaryText, fontSize: 17, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text('Essayez un autre horaire ou une autre date', style: TextStyle(color: c.secondaryText, fontSize: 13), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => setState(() { _step = 2; _selectedHeure = null; _selectedTerrain = null; _selectedProduit = null; }),
                      style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text("Changer l'horaire"),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => setState(() { _step = 1; _selectedDate = null; _selectedHeure = null; _selectedTerrain = null; _selectedProduit = null; }),
                      style: OutlinedButton.styleFrom(foregroundColor: primary, side: const BorderSide(color: primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('Changer la date'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final dateLabel = _selectedDate != null ? _terrainDateLabel(_selectedDate!) : '';
        final timeStr = _selectedHeure != null ? formatHour(_selectedHeure!) : '';

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quel terrain ?', style: TextStyle(color: c.primaryText, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                '${terrains.length} terrain${terrains.length > 1 ? 's' : ''} disponible${terrains.length > 1 ? 's' : ''}',
                style: TextStyle(color: c.secondaryText, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: terrains.length,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemBuilder: (context, index) {
                    final t = terrains[index];
                    return _TerrainSelectCard(
                      terrain: t,
                      selectedHour: _selectedHeure,
                      selectedDate: _selectedDate,
                      dateLabel: dateLabel,
                      timeStr: timeStr,
                      sport: _selectedSport,
                      isSelected: _selectedTerrain?.id == t.id,
                      onTap: () async {
                        setState(() { _selectedTerrain = t; _selectedProduit = null; });
                        final produits = await _fetchProduits();
                        if (!mounted) return;
                        setState(() => _selectedProduit = produits.isNotEmpty ? produits.first : null);
                        _next();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConfirmerStep() {
    final c = WColors.of(context);
    bool confirming = false;
    return StatefulBuilder(
      builder: (context, setLocal) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Récapitulatif', style: TextStyle(color: c.primaryText, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Vérifiez les détails de votre réservation', style: TextStyle(color: c.secondaryText, fontSize: 14)),
            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: c.secondaryBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.cardBorder),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(sportEmoji(_selectedSport), style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Text(_selectedSport ?? '-', style: TextStyle(color: c.primaryText, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(color: c.borderInput),
                  const SizedBox(height: 12),
                  _recapRow(Icons.stadium_outlined, 'Terrain', _selectedTerrain?.nom ?? '-', c),
                  _recapRow(Icons.inventory_2_outlined, 'Produit', _selectedProduit?.nom ?? '-', c),
                  _recapRow(Icons.calendar_today_outlined, 'Date', _selectedDate != null ? _formatDate(_selectedDate!) : '-', c),
                  _recapRow(Icons.access_time_outlined, 'Heure', _selectedHeure != null ? formatHour(_selectedHeure!) : '-', c),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total à payer', style: TextStyle(color: c.primaryText, fontWeight: FontWeight.w600, fontSize: 14)),
                        Text(
                          _selectedProduit?.prixUnitaire != null
                              ? '${_selectedProduit!.prixUnitaire!.toStringAsFixed(0)} MAD'
                              : '-',
                          style: const TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: confirming ? null : () async {
                  setLocal(() => confirming = true);
                  String? errorMsg;
                  try {
                    await _createReservation();
                  } catch (e) {
                    errorMsg = e.toString();
                  } finally {
                    if (mounted) setLocal(() => confirming = false);
                  }
                  if (!mounted) return;
                  if (errorMsg != null) {
                    showErrorSnackbar(this.context, 'Erreur: $errorMsg');
                  } else {
                    setState(() => _step = 5);
                    _loadAmis();
                  }
                },
                icon: confirming
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_circle_outline),
                label: const Text('Confirmer la réservation', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recapRow(IconData icon, String label, String value, WColors c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: c.secondaryText),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: c.secondaryText, fontSize: 13)),
          const Spacer(),
          Text(value, style: TextStyle(color: c.primaryText, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  int get _maxInvites => _selectedSport?.toLowerCase() == 'padel' ? 3 : 9;

  Widget _buildInviterStep() {
    final c = WColors.of(context);
    final maxInvites = _maxInvites;
    final remaining = maxInvites - _selectedAmiIds.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: Icon(Icons.check_circle, color: primary, size: 56)),
          const SizedBox(height: 12),
          Center(
            child: Text('Réservation confirmée!', style: TextStyle(color: c.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Tu peux inviter jusqu\'à $maxInvites ami${maxInvites > 1 ? 's' : ''}',
              style: TextStyle(color: c.secondaryText, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              color: c.secondaryBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.cardBorder),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _inviteQuery = v),
              style: TextStyle(color: c.primaryText, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Rechercher un ami...',
                hintStyle: TextStyle(color: c.secondaryText),
                prefixIcon: Icon(Icons.search, color: c.secondaryText, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (!_amisLoaded)
            const Expanded(child: Center(child: CircularProgressIndicator(color: primary)))
          else if (_amis.isEmpty)
            Expanded(child: Center(child: Text('Aucun ami à inviter', style: TextStyle(color: c.secondaryText))))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _amis.where((a) => _inviteQuery.isEmpty || a.fullName.toLowerCase().contains(_inviteQuery.toLowerCase())).length,
                itemBuilder: (context, index) {
                  final ami = _amis.where((a) => _inviteQuery.isEmpty || a.fullName.toLowerCase().contains(_inviteQuery.toLowerCase())).elementAt(index);
                  final isSelected = _selectedAmiIds.contains(ami.id);
                  final canSelect = isSelected || remaining > 0;
                  return GestureDetector(
                    onTap: () {
                      if (!canSelect) return;
                      setState(() {
                        if (isSelected) {
                          _selectedAmiIds.remove(ami.id);
                        } else {
                          _selectedAmiIds.add(ami.id);
                        }
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: c.secondaryBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? primary : c.borderInput,
                          width: isSelected ? 1.5 : 1,
                        ),
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
                                getInitials(ami.prenom, ami.nom),
                                style: TextStyle(color: c.secondary, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              ami.fullName,
                              style: TextStyle(
                                color: canSelect ? c.primaryText : c.secondaryText,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check, color: primary, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () async {
                final memberId = context.read<AppState>().currentMemberID;
                if (_newReservationId != null && _selectedAmiIds.isNotEmpty && memberId != null) {
                  for (final amiId in _selectedAmiIds) {
                    try {
                      await Supabase.instance.client
                          .from(SupabaseConstants.invitationTable)
                          .insert({
                            'Réservation': _newReservationId,
                            'Invité': amiId,
                            'Inviteur': memberId,
                            'Statut': 'en attente',
                          });
                    } catch (_) {}
                  }
                }
                if (mounted) {
                  context.read<AppState>().markReservationCreated();
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                _selectedAmiIds.isEmpty ? 'Terminer sans inviter' : 'Inviter ${_selectedAmiIds.length} ami${_selectedAmiIds.length > 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TerrainSelectCard extends StatefulWidget {
  final TerrainModel terrain;
  final double? selectedHour;
  final DateTime? selectedDate;
  final String dateLabel;
  final String timeStr;
  final String? sport;
  final bool isSelected;
  final VoidCallback onTap;

  const _TerrainSelectCard({
    required this.terrain,
    required this.selectedHour,
    required this.selectedDate,
    required this.dateLabel,
    required this.timeStr,
    required this.onTap,
    this.sport,
    this.isSelected = false,
  });

  @override
  State<_TerrainSelectCard> createState() => _TerrainSelectCardState();
}

class _TerrainSelectCardState extends State<_TerrainSelectCard> {
  double? _price;

  @override
  void initState() {
    super.initState();
    _fetchProduit();
  }

  Future<void> _fetchProduit() async {
    try {
      final data = await Supabase.instance.client
          .from(SupabaseConstants.produitTable)
          .select()
          .eq('Terrain', widget.terrain.id);

      if (!mounted) return;
      final list = data as List;
      if (list.isEmpty) return;

      final hour = widget.selectedHour;
      final date = widget.selectedDate;
      final dayNum = date != null ? (date.weekday == 7 ? 0 : date.weekday) : null;

      final dayFiltered = dayNum == null
          ? list
          : list.where((p) {
              final days = p['days'] as String?;
              if (days == null || days.trim().isEmpty) return true;
              final available = days
                  .split(',')
                  .map((d) => int.tryParse(d.trim()))
                  .whereType<int>()
                  .toSet();
              return available.contains(dayNum);
            }).toList();

      final candidates = dayFiltered.isNotEmpty ? dayFiltered : list;

      Map<String, dynamic>? matched;
      for (final p in candidates) {
        final startAt = (p['Start_at'] as num?)?.toDouble();
        final endAt = (p['End_at'] as num?)?.toDouble();
        if (startAt != null && endAt != null && hour != null &&
            hour >= startAt && hour < endAt) {
          matched = p;
          break;
        }
      }
      matched ??= candidates.first;

      setState(() {
        _price = (matched!['Prix unitaire'] as num?)?.toDouble();
      });
    } catch (_) {}
  }

  String _fallbackImageUrl() {
    switch (widget.sport?.toLowerCase()) {
      case 'foot':
      case 'football':
        return 'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=400&h=250&fit=crop';
      case 'padel':
        return 'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=400&h=250&fit=crop';
      case 'basket':
      case 'basketball':
        return 'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=400&h=250&fit=crop';
      default:
        return '';
    }
  }

  int _joueursCount() {
    switch (widget.sport?.toLowerCase()) {
      case 'padel': return 4;
      default: return 10;
    }
  }

  String _joueurs() {
    return '${_joueursCount()} joueurs';
  }

  @override
  Widget build(BuildContext context) {
    final c = WColors.of(context);
    final t = widget.terrain;
    final imageUrl = (t.img != null && t.img!.isNotEmpty) ? t.img! : _fallbackImageUrl();

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: c.secondaryBackground,
          borderRadius: BorderRadius.circular(16),
          border: widget.isSelected ? Border.all(color: primary, width: 2) : null,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(c),
                    )
                  : _placeholder(c),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.nom ?? 'Terrain',
                          style: TextStyle(color: c.primaryText, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(_joueurs(), style: TextStyle(color: c.secondaryText, fontSize: 12)),
                            if (widget.terrain.format != null && widget.terrain.format!.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(widget.terrain.format!, style: const TextStyle(color: primary, fontWeight: FontWeight.w600, fontSize: 12)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (widget.dateLabel.isNotEmpty || widget.timeStr.isNotEmpty)
                        Text(
                          '${widget.dateLabel}  ${widget.timeStr}',
                          style: TextStyle(color: c.secondaryText, fontSize: 12),
                        ),
                      if (_price != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${_price!.toStringAsFixed(0)} MAD',
                          style: const TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(WColors c) => Container(
    height: 160,
    width: double.infinity,
    color: c.alternate,
    child: Center(child: Icon(Icons.sports, size: 48, color: c.secondaryText)),
  );
}
