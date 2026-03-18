import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/mqtt.dart';
import '../providers/connectivity_provider.dart';
import '../data/hive_auth_repository.dart';
import '../domain/auth_interface.dart';
import '../widgets/meter_info_card.dart';
import '../widgets/smart_data_card.dart';

class SensorScreen extends StatefulWidget {
  const SensorScreen({super.key});

  @override
  State<SensorScreen> createState() => _SensorScreenState();
}

class _SensorScreenState extends State<SensorScreen> {
  final TextEditingController _readingController = TextEditingController();
  List<Map<String, String>> _history = [];
  User? _currentUser;
  String _meterType = 'electricity';
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MqttProvider>().connect();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _meterType = ModalRoute.of(context)?.settings.arguments as String? ?? 'electricity';
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await authRepository.getCurrentUser();
    if (user != null) {
      final history = await authRepository.getMeterHistory(user.email, _meterType);
      if (mounted) setState(() { _currentUser = user; _history = history; _isLoadingHistory = false; });
    }
  }

  @override
  void dispose() {
    _readingController.dispose();
    super.dispose();
  }

  Future<void> _saveRecord(User user, String value, String source) async {
    final messenger = ScaffoldMessenger.of(context);
    final date = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now());
    await authRepository.addMeterHistory(user.email, _meterType, {'date': date, 'value': value, 'source': source});
    _loadData();
    messenger.showSnackBar(SnackBar(content: Text('Показники успішно збережено! ($source)'), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    final mqtt = context.watch<MqttProvider>();
    final hasInternet = context.watch<ConnectivityProvider>().hasInternet;
    final user = _currentUser;

    if (_isLoadingHistory || user == null) {
      return Scaffold(appBar: AppBar(title: const Text('Завантаження...'), backgroundColor: Colors.teal), body: const Center(child: CircularProgressIndicator()));
    }

    String pageTitle = 'Лічильник', unit = '', smartValue = '0', modelName = 'NІК 2300AP3', resolution = '6.2';
    IconData headerIcon = Icons.sensors;
    Color headerColor = Colors.teal;

    if (_meterType == 'electricity') {
      pageTitle = 'Електроенергія'; headerIcon = Icons.bolt; headerColor = Colors.amber.shade700; unit = 'кВт⋅год'; modelName = 'NІК 2300AP3 T.2000.MC.11'; smartValue = mqtt.electricityValue;
    } else if (_meterType == 'gas') {
      pageTitle = 'Газопостачання'; headerIcon = Icons.local_fire_department; headerColor = Colors.deepOrange; unit = 'м³'; modelName = 'Samgas G4'; resolution = '5.3'; smartValue = mqtt.gasValue;
    } else if (_meterType == 'water') {
      pageTitle = 'Водопостачання'; headerIcon = Icons.water_drop; headerColor = Colors.blue; unit = 'м³'; modelName = 'Novator ЛК-15'; resolution = '5.0'; smartValue = mqtt.waterValue;
    }

    return Scaffold(
      appBar: AppBar(title: Text(pageTitle), backgroundColor: headerColor, foregroundColor: Colors.white),
      body: Column(
        children: [
          if (!hasInternet)
            Container(
              width: double.infinity,
              color: Colors.red.shade400,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('ОФЛАЙН: Показано збережені дані', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MeterInfoCard(headerIcon: headerIcon, headerColor: headerColor, accountNumber: '104-2026-8842', serialNumber: '20865142', installDate: '20.08.2025', modelName: modelName, resolution: resolution),
                  const SizedBox(height: 24),
                  SmartDataCard(headerColor: headerColor, smartValue: smartValue, unit: unit, isConnected: mqtt.isConnected, onSave: () => _saveRecord(user, smartValue, 'Авто (MQTT)')),
                  const SizedBox(height: 24),
                  const Text('Передати вручну', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _readingController, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'Введіть значення', border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 12), suffixIcon: IconButton(icon: const Icon(Icons.camera_alt, color: Colors.teal), onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Камера активується...'))))))),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: headerColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20)),
                        onPressed: hasInternet ? () { // Блокуємо кнопку, якщо офлайн
                          if (_readingController.text.isNotEmpty) { _saveRecord(user, _readingController.text, 'Вручну'); _readingController.clear(); FocusScope.of(context).unfocus(); }
                        } : null,
                        child: const Text('ДОДАТИ'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text('Історія показників', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_history.isEmpty) const Padding(padding: EdgeInsets.all(16.0), child: Text('Історія порожня.', style: TextStyle(color: Colors.grey)))
                  else ..._history.map((record) => Card(elevation: 0, color: Colors.grey.shade50, margin: const EdgeInsets.only(bottom: 8), child: ListTile(leading: Icon(record['source'] == 'Вручну' ? Icons.edit_note : Icons.memory, color: Colors.grey), title: Text('${record['value']} $unit', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), subtitle: Text('Джерело: ${record['source']}'), trailing: Text(record['date']!)))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}