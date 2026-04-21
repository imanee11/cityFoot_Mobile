import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/amis_model.dart';
import '../../models/member_model.dart';
import '../../widgets/initials_avatar.dart';

class AmiCard extends StatelessWidget {
  final AmisModel ami;
  final MemberModel? amiMember;
  final VoidCallback onDelete;

  const AmiCard({
    super.key,
    required this.ami,
    required this.amiMember,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = WColors.of(context);
    final name = amiMember?.fullName ?? 'Ami';
    final initials = amiMember?.initials ?? '?';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.cardBorder),
      ),
      child: Row(
        children: [
          InitialsAvatar(
            initials: initials,
            size: 44,
            imageUrl: amiMember?.img,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: c.primaryText,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'En ligne',
                      style: TextStyle(color: c.secondaryText, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: c.secondaryBackground,
                title: Text('Supprimer ami',
                    style: TextStyle(color: c.primaryText)),
                content: Text(
                  'Supprimer $name de vos amis?',
                  style: TextStyle(color: c.secondaryText),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Annuler',
                        style: TextStyle(color: c.secondaryText)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onDelete();
                    },
                    child: const Text('Supprimer',
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
