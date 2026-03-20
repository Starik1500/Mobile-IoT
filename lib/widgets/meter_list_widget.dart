import 'package:flutter/material.dart';

class MeterListItem extends StatelessWidget {
  final String meterKey;
  final String reading;
  final VoidCallback onDelete;
  final VoidCallback onRefresh;

  MeterListItem({super.key, required this.meterKey, required this.reading, required this.onDelete, required this.onRefresh});

  final Map<String, Map<String, dynamic>> meterDetails = {
    'electricity': {'title': 'Електроенергія', 'address': 'Гуртожиток НУ ЛП', 'icon': Icons.bolt, 'color': Colors.amber.shade700, 'unit': 'кВт⋅год'},
    'gas': {'title': 'Газопостачання', 'address': 'Тернопільська обл.', 'icon': Icons.local_fire_department, 'color': Colors.deepOrange, 'unit': 'м³'},
    'water': {'title': 'Водопостачання', 'address': 'Гуртожиток НУ ЛП', 'icon': Icons.water_drop, 'color': Colors.blue, 'unit': 'м³'},
  };

  @override
  Widget build(BuildContext context) {
    final data = meterDetails[meterKey]!;

    return Dismissible(
      key: Key(meterKey),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 20.0), color: Colors.red,
        child: const Row(children: [Icon(Icons.delete, color: Colors.white), SizedBox(width: 8), Text('Видалити', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20.0), color: Colors.blue,
        child: const Row(mainAxisAlignment: MainAxisAlignment.end, children: [Text('Деталі', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), SizedBox(width: 8), Icon(Icons.settings, color: Colors.white)]),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) return true;
        await Navigator.pushNamed(context, '/sensor', arguments: meterKey);
        onRefresh();
        return false;
      },
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: () async {
          await Navigator.pushNamed(context, '/sensor', arguments: meterKey);
          onRefresh();
        },
        child: Card(
          elevation: 2, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: data['color'].withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(data['icon'], color: data['color'], size: 28)),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(data['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 4),
                      Row(children: [const Icon(Icons.location_on, size: 14, color: Colors.grey), const SizedBox(width: 4), Expanded(child: Text(data['address'], style: const TextStyle(fontSize: 13, color: Colors.grey)))])
                    ])),
                  ],
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Останній показник (з бази)', style: TextStyle(fontSize: 12, color: Colors.grey)), const SizedBox(height: 4),
                      Text('$reading ${reading != 'Немає даних' ? data['unit'] : ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ]),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)), child: const Text('Синхронізовано', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold))),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}