import 'package:flutter/material.dart';

class MeterInfoCard extends StatelessWidget {
  final IconData headerIcon;
  final Color headerColor;
  final String accountNumber;
  final String serialNumber;
  final String installDate;
  final String modelName;
  final String resolution;

  const MeterInfoCard({
    super.key, required this.headerIcon, required this.headerColor, required this.accountNumber,
    required this.serialNumber, required this.installDate, required this.modelName, required this.resolution,
  });

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(headerIcon, color: headerColor), const SizedBox(width: 8),
              Text('О/Р: $accountNumber', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow('Номер лічильника:', serialNumber),
          _buildInfoRow('Встановлено з:', installDate),
          _buildInfoRow('Тип:', modelName),
          _buildInfoRow('Розрядність:', resolution),
        ],
      ),
    );
  }
}