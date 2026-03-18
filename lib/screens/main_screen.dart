import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';
import '../data/hive_auth_repository.dart';
import '../data/api_repository.dart';
import '../domain/auth_interface.dart';
import '../widgets/meter_list_widget.dart';
import '../widgets/add_meter_sheet.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late Future<Map<String, dynamic>> _screenDataFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _screenDataFuture = _fetchScreenData();
    });
  }

  Future<Map<String, dynamic>> _fetchScreenData() async {
    final localUser = await authRepository.getCurrentUser();
    if (localUser == null) return {};

    final user = await apiRepository.syncUserData(localUser.email) ?? localUser;

    final Map<String, String> readings = {};
    for (String meter in user.meters) {
      final history = await authRepository.getMeterHistory(user.email, meter);
      readings[meter] = history.isNotEmpty ? history.first['value'].toString() : 'Немає даних';
    }
    return {'user': user, 'readings': readings};
  }

  Future<void> _deleteMeter(User user, int index) async {
    final newMeters = List<String>.from(user.meters)..removeAt(index);
    final updatedUser = User(
      name: user.name, email: user.email, address: user.address,
      password: user.password, meters: newMeters, avatarPath: user.avatarPath,
    );
    await authRepository.updateUser(updatedUser);
    _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    final hasInternet = context.watch<ConnectivityProvider>().hasInternet;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Об\'єкти обліку'), backgroundColor: Colors.teal, foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () async {
              await Navigator.pushNamed(context, '/profile');
              _refreshData();
            },
          )
        ],
      ),
      body: Column(
        children: [
          if (!hasInternet)
            Container(
              width: double.infinity, color: Colors.red, padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Text('Офлайн режим (Дані з локальної бази)', textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
            ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _screenDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.teal));
                }
                if (!snapshot.hasData || snapshot.data!['user'] == null) {
                  return const Center(child: Text('Помилка завантаження даних'));
                }

                final user = snapshot.data!['user'] as User;
                final readings = snapshot.data!['readings'] as Map<String, String>;

                if (user.meters.isEmpty) return buildEmptyState(context, user, _refreshData);

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0), itemCount: user.meters.length,
                  itemBuilder: (context, index) {
                    return MeterListItem(
                      meterKey: user.meters[index],
                      reading: readings[user.meters[index]] ?? 'Немає даних',
                      onDelete: () => _deleteMeter(user, index),
                      onRefresh: _refreshData,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FutureBuilder<Map<String, dynamic>>(
          future: _screenDataFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!['user'] == null) return const SizedBox();
            return FloatingActionButton(
              onPressed: () => showAddMeterModal(context, snapshot.data!['user'], _refreshData),
              backgroundColor: Colors.teal, foregroundColor: Colors.white, child: const Icon(Icons.add),
            );
          }
      ),
    );
  }
}