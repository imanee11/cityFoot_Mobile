import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/supabase_constants.dart';
import '../../models/invitation_model.dart';
import '../../models/reservation_model.dart';
import '../../providers/match_provider.dart';
import '../../core/utils/helpers.dart';

class InvitationCard extends StatefulWidget {
  final InvitationModel invitation;

  const InvitationCard({super.key, required this.invitation});

  @override
  State<InvitationCard> createState() => _InvitationCardState();
}

class _InvitationCardState extends State<InvitationCard> {
  ReservationModel? _reservation;
  String? _inviteurName;
  String? _inviteurInitials;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final resData = await Supabase.instance.client
          .from(SupabaseConstants.reservationTable)
          .select()
          .eq('id', widget.invitation.reservation)
          .single();
      final res = ReservationModel.fromJson(resData);

      final orgData = await Supabase.instance.client
          .from(SupabaseConstants.memberTable)
          .select('Prénom,Nom')
          .eq('id', widget.invitation.inviteur)
          .single();

      final prenom = orgData['Prénom'] as String? ?? '';
      final nom = orgData['Nom'] as String? ?? '';
      final initials =
          '${prenom.isNotEmpty ? prenom[0].toUpperCase() : ''}${nom.isNotEmpty ? nom[0].toUpperCase() : ''}';

      if (mounted) {
        setState(() {
          _reservation = res;
          _inviteurName = '$prenom $nom'.trim();
          _inviteurInitials = initials;
        });
      }
    } catch (_) {}
  }

  String _sportEmoji(String? sport) {
    switch (sport?.toLowerCase()) {
      case 'football':
        return '⚽';
      case 'padel':
        return '🎾';
      case 'basket':
      case 'basketball':
        return '🏀';
      default:
        return '🏟️';
    }
  }

  String _formatHour(double h) {
    final hour = h.floor();
    final minutes = ((h - hour) * 60).round();
    return '${hour.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = WColors.of(context);
    final matchProvider = context.read<MatchProvider>();
    final statut = widget.invitation.statut;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: _reservation == null
          ? const Padding(
              padding: EdgeInsets.all(12),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: primary, strokeWidth: 2),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _inviteurInitials ?? '?',
                          style: const TextStyle(
                            color: primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: _inviteurName ?? '...',
                              style: TextStyle(
                                color: c.primaryText,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            TextSpan(
                              text: " t'invite à rejoindre",
                              style: TextStyle(
                                color: c.secondaryText,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c.primaryBackground,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          _sportEmoji(_reservation!.sport),
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _reservation!.titre ??
                                _reservation!.sport ??
                                'Match',
                            style: TextStyle(
                              color: c.primaryText,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              if (_reservation!.heureDebut != null) ...[
                                Icon(Icons.access_time_outlined,
                                    size: 12, color: c.secondaryText),
                                const SizedBox(width: 3),
                                Text(
                                  _formatHour(_reservation!.heureDebut!),
                                  style: TextStyle(
                                    color: c.secondaryText,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                              if (_reservation!.dateDeResa != null) ...[
                                Icon(Icons.calendar_today_outlined,
                                    size: 12, color: c.secondaryText),
                                const SizedBox(width: 3),
                                Text(
                                  DateFormat('dd MMM', 'fr')
                                      .format(_reservation!.dateDeResa!),
                                  style: TextStyle(
                                    color: c.secondaryText,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                if (statut == 'en attente')
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              await matchProvider.accepterInvitation(
                                widget.invitation.id,
                                widget.invitation.invite,
                              );
                            } catch (e) {
                              if (context.mounted) {
                                showErrorSnackbar(
                                    context, 'Erreur: ${e.toString()}');
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text(
                            'Accepter',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            try {
                              await matchProvider
                                  .refuserInvitation(widget.invitation.id);
                            } catch (e) {
                              if (context.mounted) {
                                showErrorSnackbar(
                                    context, 'Erreur: ${e.toString()}');
                              }
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: c.secondaryText,
                            side: BorderSide(color: c.borderInput),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text(
                            'Refuser',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  )
                else if (statut == 'accepté')
                  const Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: successGreen, size: 18),
                      SizedBox(width: 6),
                      Text(
                        '✓ Acceptée',
                        style: TextStyle(
                          color: successGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  )
                else if (statut == 'refusé')
                  Row(
                    children: [
                      Icon(Icons.cancel_outlined,
                          color: c.secondaryText, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '✗ Refusée',
                        style: TextStyle(
                          color: c.secondaryText,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
    );
  }
}
