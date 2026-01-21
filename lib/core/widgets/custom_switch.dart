import 'package:flutter/material.dart';

/// Switch personalizado reutilizable con colores de la app
class CustomSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeTrackColor;
  final Color? inactiveTrackColor;
  final Color? activeThumbColor;
  final Color? inactiveThumbColor;

  const CustomSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.activeTrackColor,
    this.inactiveTrackColor,
    this.activeThumbColor,
    this.inactiveThumbColor,
  });

  @override
  Widget build(BuildContext context) {
    final defaultActiveColor = const Color(0xFFE84343);

    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: activeThumbColor ?? Colors.white,
      activeTrackColor: activeTrackColor ?? defaultActiveColor,
      inactiveThumbColor: inactiveThumbColor ?? Colors.grey[400],
      inactiveTrackColor: inactiveTrackColor ?? Colors.grey[300],
    );
  }
}
