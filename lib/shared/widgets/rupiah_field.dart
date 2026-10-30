import 'package:flutter/material.dart';

import '../../core/utils/rupiah_input_formatter.dart';

/// Kolom isian nominal Rupiah (diformat otomatis saat diketik).
/// Nilainya dibaca dengan parseRupiahInput(controller.text).
class RupiahField extends StatelessWidget {
  const RupiahField({
    super.key,
    required this.controller,
    required this.label,
    this.helperText,
    this.onChanged,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final String? helperText;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: textInputAction,
      inputFormatters: const [RupiahInputFormatter()],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixText: 'Rp ',
        helperText: helperText,
        helperMaxLines: 2,
      ),
    );
  }
}
