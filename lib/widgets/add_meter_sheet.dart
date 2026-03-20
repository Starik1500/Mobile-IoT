import 'package:flutter/material.dart';
import '../domain/auth_interface.dart';
import '../data/hive_auth_repository.dart';

Future<void> _simulateImport(BuildContext context, BuildContext sheetContext, User user, String key, String providerName, VoidCallback onRefresh) async {
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);

  Navigator.of(sheetContext).pop();

  showDialog(
    context: context, barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(content: Row(children: [const CircularProgressIndicator(color: Colors.teal), const SizedBox(width: 20), Text('Зв\'язок з $providerName...')])),
  );

  await Future.delayed(const Duration(seconds: 2));
  navigator.pop();

  if (!user.meters.contains(key)) {
    final newMeters = List<String>.from(user.meters)..add(key);
    final updatedUser = User(name: user.name, email: user.email, address: user.address, password: user.password, meters: newMeters, avatarPath: user.avatarPath);
    await authRepository.updateUser(updatedUser);
    onRefresh();
    messenger.showSnackBar(const SnackBar(content: Text('Об\'єкт успішно синхронізовано!'), backgroundColor: Colors.green));
  }
}

void showAddMeterModal(BuildContext context, User user, VoidCallback onRefresh) {
  showModalBottomSheet(
    context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (BuildContext sheetContext) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20, top: 16, left: 16, right: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Додати пристрій обліку', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
            const Text('Оберіть спосіб синхронізації', style: TextStyle(color: Colors.grey)), const Divider(height: 32),
            if (!user.meters.contains('electricity')) ListTile(leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.cloud_sync, color: Colors.white)), title: const Text('Імпорт з Обленерго'), trailing: const Icon(Icons.chevron_right), onTap: () => _simulateImport(context, sheetContext, user, 'electricity', 'Обленерго', onRefresh)),
            if (!user.meters.contains('gas')) ListTile(leading: const CircleAvatar(backgroundColor: Colors.deepOrange, child: Icon(Icons.cloud_sync, color: Colors.white)), title: const Text('Імпорт з Нафтогазу'), trailing: const Icon(Icons.chevron_right), onTap: () => _simulateImport(context, sheetContext, user, 'gas', 'Нафтогаз', onRefresh)),
            if (!user.meters.contains('water')) ListTile(leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.cloud_sync, color: Colors.white)), title: const Text('Імпорт з Водоканалу'), trailing: const Icon(Icons.chevron_right), onTap: () => _simulateImport(context, sheetContext, user, 'water', 'Водоканал', onRefresh)),
            if (user.meters.length == 3) const Padding(padding: EdgeInsets.all(16.0), child: Center(child: Text('Усі можливі об\'єкти вже підключено!', style: TextStyle(color: Colors.grey)))),
          ],
        ),
      );
    },
  );
}

Widget buildEmptyState(BuildContext context, User user, VoidCallback onRefresh) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.domain_disabled, size: 80, color: Colors.grey.shade400), const SizedBox(height: 16),
        const Text('Немає підключених об\'єктів', style: TextStyle(fontSize: 18, color: Colors.grey)), const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => showAddMeterModal(context, user, onRefresh),
          icon: const Icon(Icons.cloud_sync), label: const Text('ІМПОРТУВАТИ ДАНІ'), style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
        )
      ],
    ),
  );
}