import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class SearchBarWidget extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final String hint;

  const SearchBarWidget({
    super.key,
    required this.onChanged,
    this.hint = 'Rechercher...',
  });

  @override
  Widget build(BuildContext context) {
    final c = WColors.of(context);
    return TextField(
      onChanged: onChanged,
      style: TextStyle(color: c.primaryText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.secondaryText),
        prefixIcon: Icon(Icons.search, color: c.secondaryText),
        filled: true,
        fillColor: c.secondaryBackground,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.secondaryText, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.secondaryText, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
    );
  }
}
