import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT Lab 1',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'IoT Lab 1: Input Logic'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({required this.title, super.key});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  final TextEditingController _inputController = TextEditingController();

  void _handleInput() {
    setState(() {
      final String input = _inputController.text;

      if (input == 'Avada Kedavra') {
        _counter = 0;
      } else {
        final int? valueToAdd = int.tryParse(input);

        if (valueToAdd != null) {
          _counter += valueToAdd;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Введіть число або закляття!')),
          );
        }
      }
      _inputController.clear();
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Current counter value:',
              ),
              Text(
                '$_counter',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _inputController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Введіть число або Avada Kedavra',
                ),
                keyboardType: TextInputType.text,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleInput,
        tooltip: 'Execute',
        child: const Icon(Icons.check),
      ),
    );
  }
}
