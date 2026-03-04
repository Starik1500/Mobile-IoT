import 'package:flutter/material.dart';
import '../data/hive_auth_repository.dart';
import '../domain/auth_interface.dart';
import '../widgets/meter_card.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  User? _currentUser;
  bool _isLoading = true;

  final Map<String, MeterCard> _allMeters = {
    'electricity': const MeterCard(title: 'Електроенергія', icon: Icons.bolt, value: '0 кВт⋅год', color: Colors.amber),
    'gas': const MeterCard(title: 'Газопостачання', icon: Icons.local_fire_department, value: '0 м³', color: Colors.deepOrange),
    'water': const MeterCard(title: 'Водопостачання', icon: Icons.water_drop, value: '0 м³', color: Colors.blue),
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await authRepository.getCurrentUser();
    setState(() {
      _currentUser = user;
      _isLoading = false;
    });
  }

  Future<void> _updateUserMeters(List<String> newMeters) async {
    if (_currentUser != null) {
      final updatedUser = User(
        name: _currentUser!.name,
        email: _currentUser!.email,
        address: _currentUser!.address,
        password: _currentUser!.password,
        meters: newMeters,
      );

      await authRepository.updateUser(updatedUser);
      setState(() {
        _currentUser = updatedUser;
      });
    }
  }

  void _showAddMeterModal() {
    if (_currentUser == null) return;

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

              ..._allMeters.keys.where((key) => !_currentUser!.meters.contains(key)).map((key) {
                return ListTile(
                  leading: Icon(_allMeters[key]!.icon, color: _allMeters[key]!.color),
                  title: Text(_allMeters[key]!.title),
                  onTap: () {
                    final newMeters = List<String>.from(_currentUser!.meters)..add(key);
                    _updateUserMeters(newMeters);
                    Navigator.pop(context);
                  },
                );
              }),

              if (_allMeters.keys.where((key) => !_currentUser!.meters.contains(key)).isEmpty)
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
            onPressed: () async {
              await Navigator.pushNamed(context, '/profile');
              _loadUserData();
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: _currentUser!.meters.isEmpty
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
            : ListView.builder(
          itemCount: _currentUser!.meters.length,
          itemBuilder: (context, index) {
            final meterKey = _currentUser!.meters[index];
            final meterCard = _allMeters[meterKey]!;

            return Dismissible(
              key: Key(meterKey),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20.0),
                color: Colors.red,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (direction) {
                final newMeters = List<String>.from(_currentUser!.meters)..removeAt(index);
                _updateUserMeters(newMeters);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${meterCard.title} видалено')),
                );
              },
              child: meterCard,
            );
          },
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