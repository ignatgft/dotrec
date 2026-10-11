import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class DotSwitch extends StatelessWidget {
  const DotSwitch({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
    this.subtitle,
  });

  final bool value;
  final String label;
  final ValueChanged<bool>? onChanged;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(fontSize: 12, color: context.dot.fgMuted),
                ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: context.dot.fg,
          activeTrackColor: context.dot.surfaceRaised,
          inactiveThumbColor: context.dot.fgMuted,
          inactiveTrackColor: context.dot.surfaceRaised,
        ),
      ],
    );
  }
}
