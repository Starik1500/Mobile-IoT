import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final userName = args?['name']?.toString() ?? 'Невідомий користувач';
    final userEmail = args?['email']?.toString() ?? 'Немає пошти';
    final userAddress = args?['address']?.toString() ?? 'Адресу не вказано';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мій Профіль'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                border: Border.all(color: Colors.teal, width: 2),
                borderRadius: BorderRadius.zero,
              ),
              child: const Icon(Icons.person, size: 80, color: Colors.teal),
            ),
            const SizedBox(height: 24),

            Text(userName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(userEmail, style: const TextStyle(fontSize: 16, color: Colors.grey)),
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
                  const Text('Адреса надання послуг:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                  const SizedBox(height: 12),
                  Text(userAddress, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: size.width, height: 50,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red, side: const BorderSide(color: Colors.red, width: 2), shape: const RoundedRectangleBorder(),
                ),
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                },
                child: const Text('ВИЙТИ З АКАУНТУ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}