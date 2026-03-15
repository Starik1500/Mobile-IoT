import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';
import '../data/hive_auth_repository.dart';
import '../domain/auth_interface.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  User? _currentUser;
  bool _isLoading = true;

  final Map<String, String> _lastReadings = {};

  final Map<String, Map<String, dynamic>> _meterDetails = {
    'electricity': {
      'title': 'Електроенергія (Дім)',
      'address': 'м. Львів, НУ ЛП, Гуртожиток',
      'icon': Icons.bolt,
      'color': Colors.amber.shade700,
      'unit': 'кВт⋅год',
    },
    'gas': {
      'title': 'Газопостачання',
      'address': 'Тернопільська обл.',
      'icon': Icons.local_fire_department,
      'color': Colors.deepOrange,
      'unit': 'м³',
    },
    'water': {
      'title': 'Водопостачання (Холодна)',
      'address': 'м. Львів, НУ ЛП, Гуртожиток',
      'icon': Icons.water_drop,
      'color': Colors.blue,
      'unit': 'м³',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await authRepository.getCurrentUser();
    if (user != null) {
      for (String meter in user.meters) {
        final history = await authRepository.getMeterHistory(user.email, meter);
        if (history.isNotEmpty) {
          _lastReadings[meter] = '${history.first['value']} ${_meterDetails[meter]!['unit']}';
        } else {
          _lastReadings[meter] = 'Немає даних';
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _currentUser = user;
      _isLoading = false;
    });
  }

  Future<void> _updateUserMeters(User user, List<String> newMeters) async {
    final updatedUser = User(
      name: user.name,
      email: user.email,
      address: user.address,
      password: user.password,
      meters: newMeters,
      avatarPath: user.avatarPath,
    );

    setState(() {
      _currentUser = updatedUser;
    });

    await authRepository.updateUser(updatedUser);
    _loadUserData();
  }

  Future<void> _simulateImport(BuildContext sheetContext, User user, String key, String providerName) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    Navigator.of(sheetContext).pop();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(color: Colors.teal),
            const SizedBox(width: 20),
            Text('Зв\'язок з $providerName...'),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    navigator.pop();

    if (!user.meters.contains(key)) {
      final newMeters = List<String>.from(user.meters)..add(key);
      await _updateUserMeters(user, newMeters);

      messenger.showSnackBar(
        const SnackBar(content: Text('Об\'єкт успішно синхронізовано!'), backgroundColor: Colors.green),
      );
    }
  }

  void _showAddMeterModal(User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20, top: 16, left: 16, right: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Додати пристрій обліку', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Оберіть спосіб синхронізації', style: TextStyle(color: Colors.grey)),
              const Divider(height: 32),

              if (!user.meters.contains('electricity'))
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.cloud_sync, color: Colors.white)),
                  title: const Text('Імпорт з Обленерго'),
                  subtitle: const Text('Синхронізація за О/Р'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _simulateImport(sheetContext, user, 'electricity', 'Обленерго'),
                ),
              if (!user.meters.contains('gas'))
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.deepOrange, child: Icon(Icons.cloud_sync, color: Colors.white)),
                  title: const Text('Імпорт з Нафтогазу'),
                  subtitle: const Text('Синхронізувати газові точки'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _simulateImport(sheetContext, user, 'gas', 'Нафтогаз'),
                ),
              if (!user.meters.contains('water'))
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.cloud_sync, color: Colors.white)),
                  title: const Text('Імпорт з Водоканалу'),
                  subtitle: const Text('Підтягнути лічильники води'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _simulateImport(sheetContext, user, 'water', 'Водоканал'),
                ),

              if (user.meters.length == 3)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('Усі можливі об\'єкти вже підключено!', style: TextStyle(color: Colors.grey))),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRichMeterCard(String key, Map<String, dynamic> data) {
    final reading = _lastReadings[key] ?? 'Немає даних';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: data['color'].withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(data['icon'], color: data['color'], size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(child: Text(data['address'], style: const TextStyle(fontSize: 13, color: Colors.grey))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Останній показник (з бази)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(reading, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
                  child: const Text('Синхронізовано', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(User user) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.domain_disabled, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('Немає підключених об\'єктів', style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showAddMeterModal(user),
            icon: const Icon(Icons.cloud_sync),
            label: const Text('ІМПОРТУВАТИ ДАНІ'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasInternet = context.watch<ConnectivityProvider>().hasInternet;
    final user = _currentUser;

    if (_isLoading || user == null) {
      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(title: const Text('Об\'єкти обліку'), backgroundColor: Colors.teal),
        body: const Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Об\'єкти обліку'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () async {
              await Navigator.pushNamed(context, '/profile');
              _loadUserData();
            },
          )
        ],
      ),
      body: Column(
        children: [
          if (!hasInternet)
            Container(
              width: double.infinity,
              color: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Text('Немає підключення до Інтернету!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: user.meters.isEmpty
                  ? _buildEmptyState(user)
                  : ListView.builder(
                itemCount: user.meters.length,
                itemBuilder: (context, index) {
                  final meterKey = user.meters[index];
                  final meterData = _meterDetails[meterKey]!;

                  return Dismissible(
                    key: Key(meterKey),
                    direction: DismissDirection.horizontal,
                    background: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20.0),
                      color: Colors.red,
                      child: const Row(
                        children: [
                          Icon(Icons.delete, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Видалити', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    secondaryBackground: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20.0),
                      color: Colors.blue,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('Деталі', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Icon(Icons.settings, color: Colors.white),
                        ],
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.startToEnd) {
                        return true;
                      } else if (direction == DismissDirection.endToStart) {
                        await Navigator.pushNamed(context, '/sensor', arguments: meterKey);
                        _loadUserData();
                        return false;
                      }
                      return false;
                    },
                    onDismissed: (direction) {
                      final newMeters = List<String>.from(user.meters)..removeAt(index);
                      _updateUserMeters(user, newMeters);
                    },
                    child: InkWell(
                      onTap: () async {
                        await Navigator.pushNamed(context, '/sensor', arguments: meterKey);
                        _loadUserData();
                      },
                      child: _buildRichMeterCard(meterKey, meterData),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMeterModal(user),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}