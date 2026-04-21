import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/amis_provider.dart';
import '../../providers/member_provider.dart';
import '../../widgets/initials_avatar.dart';
import '../../core/utils/helpers.dart';

class InvitationsTab extends StatelessWidget {
  const InvitationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = WColors.of(context);
    final amisProvider = context.watch<AmisProvider>();
    final memberProvider = context.watch<MemberProvider>();
    final currentMember = memberProvider.currentMember;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Demandes reçues',
          style: TextStyle(
            color: c.primaryText,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        if (amisProvider.invitationsRecues.isEmpty)
          Text('Aucune demande reçue',
              style: TextStyle(color: c.secondaryText))
        else
          ...amisProvider.invitationsRecues.map((inv) {
            final sender = amisProvider.membersCache[inv.demandeur];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.secondaryBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.cardBorder),
              ),
              child: Row(
                children: [
                  InitialsAvatar(
                    initials: sender?.initials ?? '?',
                    size: 44,
                    imageUrl: sender?.img,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      sender?.fullName ?? 'Membre',
                      style: TextStyle(
                          color: c.primaryText, fontWeight: FontWeight.w500),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (currentMember == null) return;
                      try {
                        await amisProvider.acceptFriendRequest(
                          inv.id,
                          inv.demandeur,
                          sender?.telephone ?? '',
                          currentMember.prenom ?? '',
                          currentMember.id,
                        );
                      } catch (e) {
                        if (context.mounted) {
                          showErrorSnackbar(context, e.toString());
                        }
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Accepter',
                        style: TextStyle(
                            color: Colors.white, fontSize: 12)),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton(
                    onPressed: () async {
                      try {
                        await amisProvider.refuseFriendRequest(inv.id);
                      } catch (e) {
                        if (context.mounted) {
                          showErrorSnackbar(context, e.toString());
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Refuser',
                        style: TextStyle(
                            color: Colors.red, fontSize: 12)),
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 20),
        Text(
          'Demandes envoyées',
          style: TextStyle(
            color: c.primaryText,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        if (amisProvider.invitationsEnvoyees.isEmpty)
          Text('Aucune demande envoyée',
              style: TextStyle(color: c.secondaryText))
        else
          ...amisProvider.invitationsEnvoyees.map((inv) {
            final receiver = amisProvider.membersCache[inv.destinataire];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.secondaryBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.cardBorder),
              ),
              child: Row(
                children: [
                  InitialsAvatar(
                    initials: receiver?.initials ?? '?',
                    size: 44,
                    imageUrl: receiver?.img,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      receiver?.fullName ?? 'Membre',
                      style: TextStyle(
                          color: c.primaryText, fontWeight: FontWeight.w500),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      try {
                        await amisProvider.cancelFriendRequest(inv.id);
                      } catch (e) {
                        if (context.mounted) {
                          showErrorSnackbar(context, e.toString());
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: c.secondaryText),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Annuler',
                        style: TextStyle(
                            color: c.secondaryText, fontSize: 12)),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
