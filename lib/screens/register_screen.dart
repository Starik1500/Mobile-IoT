import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(title: const Text('Реєстрація'), backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.teal),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.water_drop, size: 60, color: Colors.blue),
                  const SizedBox(height: 24),
                  const Text('Новий акаунт', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 32),

                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Ім\'я користувача', border: OutlineInputBorder()),
                    validator: (value) => value == null || value.isEmpty ? 'Введіть своє ім\'я' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Будь ласка, введіть email';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Некоректний формат email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Адреса надання послуг', border: OutlineInputBorder()),
                    validator: (value) => value == null || value.isEmpty ? 'Адреса обов\'язкова' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Пароль', border: OutlineInputBorder()),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Будь ласка, введіть пароль';
                      if (value.length < 6) return 'Пароль має містити мінімум 6 символів';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: size.width, height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal, foregroundColor: Colors.white, shape: const RoundedRectangleBorder(),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.pushNamedAndRemoveUntil(
                            context, '/main', (route) => false,
                            arguments: {
                              'name': _nameController.text,
                              'email': _emailController.text,
                              'address': _addressController.text,
                              'meters': [],
                            },
                          );
                        }
                      },
                      child: const Text('ЗАРЕЄСТРУВАТИСЯ', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}