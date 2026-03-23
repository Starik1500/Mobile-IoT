import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../cubits/auth/auth_cubit.dart';
import '../cubits/auth/auth_state.dart';
import '../providers/connectivity_provider.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) async {
        await Future.delayed(const Duration(milliseconds: 1500));
        if (!context.mounted) return;

        if (state is AuthAuthenticated) {
          final hasInternet = await context.read<ConnectivityProvider>().checkConnectionNow();
          if (!context.mounted) return;

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
        }
        else if (state is AuthUnauthenticated || state is AuthError) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      },
      child: const Scaffold(
        backgroundColor: Colors.teal,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bolt, size: 100, color: Colors.white),
              SizedBox(height: 20),
              Text(
                'Three Blue Whales',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 40),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}