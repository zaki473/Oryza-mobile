import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String? subtitle;
  final Widget? child;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.subtitle,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 13, color: iconColor),
            const SizedBox(width: 6),
            Text(title.toUpperCase(),
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.5)),
          ]),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1a202c))),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(subtitle!, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
          ?child,
        ],
      ),
    );
  }
}