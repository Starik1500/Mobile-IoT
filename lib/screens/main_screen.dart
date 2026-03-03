import 'package:flutter/material.dart';
import '../widgets/meter_card.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<String> _activeMeters = [];
  bool _isInitialized = false;
  Map? _fullArgs;

  final Map<String, MeterCard> _allMeters = {
    'electricity': const MeterCard(title: 'Електроенергія', icon: Icons.bolt, value: '0 кВт⋅год', color: Colors.amber),
    'gas': const MeterCard(title: 'Газопостачання', icon: Icons.local_fire_department, value: '0 м³', color: Colors.deepOrange),
    'water': const MeterCard(title: 'Водопостачання', icon: Icons.water_drop, value: '0 м³', color: Colors.blue),
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _fullArgs = ModalRoute.of(context)?.settings.arguments as Map?;
      final dynamicMeters = _fullArgs?['meters'] as List?;
      _activeMeters = dynamicMeters?.cast<String>() ?? ['electricity', 'gas'];
      _isInitialized = true;
    }
  }

  void _showAddMeterModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Оберіть лічильник', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ..._allMeters.keys.where((key) => !_activeMeters.contains(key)).map((key) {
                return ListTile(
                  leading: Icon(_allMeters[key]!.icon, color: _allMeters[key]!.color),
                  title: Text(_allMeters[key]!.title),
                  onTap: () {
                    setState(() {
                      _activeMeters.add(key);
                    });
                    Navigator.pop(context);
                  },
                );
              }),
              if (_allMeters.keys.where((key) => !_activeMeters.contains(key)).isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Усі можливі лічильники вже додано!'),
                )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мої Лічильники'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Додати лічильник',
            onPressed: _showAddMeterModal,
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile', arguments: _fullArgs);
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _activeMeters.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('У вас ще немає лічильників', style: TextStyle(fontSize: 18, color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showAddMeterModal,
                icon: const Icon(Icons.add),
                label: const Text('Додати лічильник'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal, foregroundColor: Colors.white, shape: const RoundedRectangleBorder(),
                ),
              )
            ],
          ),
        )
            : ListView(
          children: _activeMeters.map((key) => _allMeters[key]!).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Камера недоступна')));
        },
        backgroundColor: Colors.teal, foregroundColor: Colors.white, shape: const RoundedRectangleBorder(),
        icon: const Icon(Icons.camera_alt), label: const Text('СКАНУВАТИ'),
      ),
    );
  }
}