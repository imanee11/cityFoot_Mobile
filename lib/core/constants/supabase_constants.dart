class SupabaseConstants {
  static const String url = 'https://fugeiwqpzlebazmekgrw.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ1Z2Vpd3FwemxlYmF6bWVrZ3J3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUyMzAyNDUsImV4cCI6MjA4MDgwNjI0NX0.QWzI2vTvIX1RAyjg4Q2YST0amIIqbH1xf1CQiwlAAa0';

  // Tables — exact names, do not change spelling or case
  static const String memberTable = 'Member';
  static const String amisTable = 'Amis';
  static const String terrainTable = 'Terrain';
  static const String reservationTable = 'Réservation';
  static const String invitationTable = 'Invitation';
  static const String produitTable = 'Produit';
  static const String operationTable = 'Opération';

  // Views — exact names, do not change
  static const String nonAmisView = 'NonAmis';
  static const String mesAmisView = 'MesAmis';

  // Edge function
  static const String whatsappFunctionUrl =
      'https://fugeiwqpzlebazmekgrw.supabase.co/functions/v1/send-whatsapp-notification';
}

// Top-level aliases kept for backward-compat with main.dart initialize call
const String supabaseUrl = SupabaseConstants.url;
const String supabaseAnonKey = SupabaseConstants.anonKey;
