import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/hive_auth_repository.dart';
import '../providers/connectivity_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    try {
      final user = await authRepository.getCurrentUser();
      if (!mounted) return;

      if (user != null) {
        final hasInternet = await context.read<ConnectivityProvider>().checkConnectionNow();

        if (!mounted) return;

        if (!hasInternet) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Вхід офлайн. Можливість оновлення даних обмежена.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      debugPrint('Помилка автологіну: $e');
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.teal,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bolt, size: 100, color: Colors.white),
            SizedBox(height: 20),
            Text('Three Blue Whales',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}