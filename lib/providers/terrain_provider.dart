import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/terrain_model.dart';
import '../core/constants/supabase_constants.dart';

class TerrainProvider extends ChangeNotifier {
  List<TerrainModel> _terrains = [];
  List<TerrainModel> _filteredTerrains = [];
  bool _isLoading = false;
  String? _error;
  String _selectedSport = 'Tous';

  List<TerrainModel> get terrains => _terrains;
  List<TerrainModel> get filteredTerrains => _filteredTerrains;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedSport => _selectedSport;

  Future<void> fetchTerrains() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data =
          await Supabase.instance.client.from(SupabaseConstants.terrainTable).select();
      _terrains = (data as List).map((e) => TerrainModel.fromJson(e)).toList();
      _applyFilter();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void filterBySport(String sport) {
    _selectedSport = sport;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_selectedSport == 'Tous') {
      _filteredTerrains = List.from(_terrains);
    } else {
      _filteredTerrains = _terrains
          .where((t) =>
              t.sport?.toLowerCase() == _selectedSport.toLowerCase())
          .toList();
    }
  }

  void clear() {
    _terrains = [];
    _filteredTerrains = [];
    _selectedSport = 'Tous';
    _error = null;
    notifyListeners();
  }
}
