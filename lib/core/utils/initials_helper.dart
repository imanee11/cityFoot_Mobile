String getInitials(String? prenom, String? nom) {
  final p = (prenom != null && prenom.isNotEmpty) ? prenom[0].toUpperCase() : '';
  final n = (nom != null && nom.isNotEmpty) ? nom[0].toUpperCase() : '';
  final result = '$p$n';
  return result.isEmpty ? 'U' : result;
}
