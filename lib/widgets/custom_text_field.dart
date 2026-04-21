import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class CustomTextField extends StatefulWidget {
  final String hint;
  final TextEditingController? controller;
  final bool obscureText;
  final bool showToggle;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final bool readOnly;

  const CustomTextField({
    super.key,
    required this.hint,
    this.controller,
    this.obscureText = false,
    this.showToggle = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.readOnly = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final c = WColors.of(context);
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      readOnly: widget.readOnly,
      style: TextStyle(color: c.primaryText),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: TextStyle(color: c.secondaryText),
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.showToggle
            ? IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  color: c.secondaryText,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
        filled: true,
        fillColor: c.secondaryBackground,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}
