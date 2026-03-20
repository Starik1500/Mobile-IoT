import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../data/hive_auth_repository.dart';
import '../domain/auth_interface.dart';
import '../widgets/profile_dialogs.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _loadUserData(); }

  Future<void> _loadUserData() async {
    final user = await authRepository.getCurrentUser();
    if (mounted) setState(() { _currentUser = user; _isLoading = false; });
  }

  Future<void> _pickAvatar(User user) async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      await authRepository.updateUser(User(name: user.name, email: user.email, address: user.address, password: user.password, meters: user.meters, avatarPath: pickedFile.path));
      _loadUserData();
    }
  }

  Future<void> _logout() async {
    await authRepository.logout();
    if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Future<void> _toggleProviderConnection(User user, String meterKey, bool isConnected, String providerName) async {
    final messenger = ScaffoldMessenger.of(context);
    List<String> newMeters = List.from(user.meters);

    if (isConnected) {
      newMeters.remove(meterKey); messenger.showSnackBar(SnackBar(content: Text('$providerName відключено.'), backgroundColor: Colors.orange));
    } else {
      newMeters.add(meterKey); messenger.showSnackBar(SnackBar(content: Text('$providerName синхронізовано!'), backgroundColor: Colors.green));
    }

    await authRepository.updateUser(User(name: user.name, email: user.email, password: user.password, address: user.address, meters: newMeters, avatarPath: user.avatarPath));
    _loadUserData();
  }

  Widget _buildProviderCard(User user, String title, String account, IconData icon, Color color, String meterKey, bool isConnected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isConnected ? color.withValues(alpha: 0.05) : Colors.white, border: Border.all(color: isConnected ? color : Colors.grey.shade300, width: isConnected ? 2 : 1)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: isConnected ? color : Colors.grey.shade200, child: Icon(icon, color: isConnected ? Colors.white : Colors.grey)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isConnected ? Colors.black : Colors.grey)), const SizedBox(height: 4),
            Text(isConnected ? 'О/Р: $account' : 'Не підключено', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ])),
          OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: isConnected ? Colors.red : Colors.teal, side: BorderSide(color: isConnected ? Colors.red : Colors.teal), shape: const RoundedRectangleBorder()),
            onPressed: () => _toggleProviderConnection(user, meterKey, isConnected, title),
            child: Text(isConnected ? 'ВІДВ\'ЯЗАТИ' : 'ДOДАТИ'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;
    if (_isLoading || user == null) return Scaffold(appBar: AppBar(title: const Text('Мій Профіль'), backgroundColor: Colors.teal), body: const Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Мій Профіль'), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _pickAvatar(user),
              child: Container(
                width: 120, height: 120, decoration: BoxDecoration(color: Colors.teal.shade50, border: Border.all(color: Colors.teal, width: 2), image: user.avatarPath != null && File(user.avatarPath!).existsSync() ? DecorationImage(image: FileImage(File(user.avatarPath!)), fit: BoxFit.cover) : null),
                child: user.avatarPath == null || !File(user.avatarPath!).existsSync() ? const Icon(Icons.person, size: 80, color: Colors.teal) : null,
              ),
            ),
            const SizedBox(height: 8), const Text('Натисніть на фото, щоб змінити', style: TextStyle(fontSize: 12, color: Colors.grey)), const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.edit, size: 20, color: Colors.teal), onPressed: () => ProfileDialogs.showEditNameDialog(context, user, _loadUserData))]),
            const SizedBox(height: 4), Text(user.email, style: const TextStyle(fontSize: 16, color: Colors.grey)), const SizedBox(height: 32),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Адреса надання послуг:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)), IconButton(icon: const Icon(Icons.edit, size: 20, color: Colors.teal), onPressed: () => ProfileDialogs.showEditAddressDialog(context, user, _loadUserData))]),
                Text(user.address, style: const TextStyle(fontSize: 16)),
              ]),
            ),
            const SizedBox(height: 32), const Align(alignment: Alignment.centerLeft, child: Text('Постачальники послуг', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))), const SizedBox(height: 16),
            _buildProviderCard(user, 'Тернопільобленерго', '104-2026-8842', Icons.bolt, Colors.amber.shade700, 'electricity', user.meters.contains('electricity')),
            _buildProviderCard(user, 'Нафтогаз України', '933-4012-0011', Icons.local_fire_department, Colors.deepOrange, 'gas', user.meters.contains('gas')),
            _buildProviderCard(user, 'Львівводоканал', 'ЛВ-88120', Icons.water_drop, Colors.blue, 'water', user.meters.contains('water')),
            const SizedBox(height: 40),
            SizedBox(width: double.infinity, height: 50, child: OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red, width: 2), shape: const RoundedRectangleBorder()), onPressed: () => ProfileDialogs.showLogoutDialog(context, _logout), child: const Text('ВИЙТИ З АКАУНТУ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
          ],
        ),
      ),
    );
  }
}