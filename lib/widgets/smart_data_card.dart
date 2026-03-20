import 'package:flutter/material.dart';

class SmartDataCard extends StatelessWidget {
  final Color headerColor;
  final String smartValue;
  final String unit;
  final bool isConnected;
  final VoidCallback onSave;

  const SmartDataCard({
    super.key, required this.headerColor, required this.smartValue,
    required this.unit, required this.isConnected, required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: headerColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: headerColor.withValues(alpha: 0.3))),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Поточні смарт-дані', style: TextStyle(color: Colors.grey)),
              Icon(isConnected ? Icons.wifi : Icons.wifi_off, color: isConnected ? Colors.green : Colors.orange, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic,
            children: [
              Text(smartValue, style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: headerColor)),
              const SizedBox(width: 8), Text(unit, style: const TextStyle(fontSize: 20, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onSave, icon: Icon(Icons.save_alt, color: headerColor),
            label: Text('ЗБЕРЕГТИ ПОКАЗНИК', style: TextStyle(color: headerColor)),
            style: OutlinedButton.styleFrom(side: BorderSide(color: headerColor)),
          )
        ],
      ),
    );
  }
}