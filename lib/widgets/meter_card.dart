import 'package:flutter/material.dart';

class MeterCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String value;
  final Color color;

  const MeterCard({
    super.key,
    required this.title,
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: const RoundedRectangleBorder(),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 8),
                  Text(
                      'Поточний показник: $value',
                      style: const TextStyle(fontSize: 16)
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}