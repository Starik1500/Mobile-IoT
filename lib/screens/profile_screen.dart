import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../data/hive_auth_repository.dart';
import '../domain/auth_interface.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _currentUser;
  bool _isLoading = true;

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

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null && _currentUser != null) {
      final updatedUser = User(
        name: _currentUser!.name,
        email: _currentUser!.email,
        address: _currentUser!.address,
        password: _currentUser!.password,
        meters: _currentUser!.meters,
        avatarPath: pickedFile.path,
      );

      await authRepository.updateUser(updatedUser);
      _loadUserData();
    }
  }

  Future<void> _logout() async {
    await authRepository.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _showEditAddressDialog() {
    final TextEditingController addressController = TextEditingController(text: _currentUser?.address);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(),
          title: const Text('Редагувати адресу'),
          content: TextField(
            controller: addressController,
            decoration: const InputDecoration(
              labelText: 'Нова адреса',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('СКАСУВАТИ', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              onPressed: () async {
                if (addressController.text.isNotEmpty && _currentUser != null) {
                  final updatedUser = User(
                    name: _currentUser!.name,
                    email: _currentUser!.email,
                    password: _currentUser!.password,
                    meters: _currentUser!.meters,
                    address: addressController.text.trim(),
                  );

                  await authRepository.updateUser(updatedUser);

                  _loadUserData();

                  if (!context.mounted) return;
                  Navigator.pop(context);
                }
              },
              child: const Text('ЗБЕРЕГТИ'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мій Профіль'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading || _currentUser == null
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickAvatar,
              child: Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  border: Border.all(color: Colors.teal, width: 2),
                  borderRadius: BorderRadius.zero,
                  image: _currentUser!.avatarPath != null
                      ? DecorationImage(
                    image: FileImage(File(_currentUser!.avatarPath!)),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: _currentUser!.avatarPath == null
                    ? const Icon(Icons.person, size: 80, color: Colors.teal)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Натисніть на фото, щоб змінити', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 24),

            Text(_currentUser!.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_currentUser!.email, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 32),

            Container(
              width: size.width,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.zero,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Адреса надання послуг:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20, color: Colors.teal),
                        onPressed: _showEditAddressDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_currentUser!.address, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: size.width, height: 50,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red, width: 2),
                  shape: const RoundedRectangleBorder(),
                ),
                onPressed: _logout,
                child: const Text('ВИЙТИ З АКАУНТУ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}