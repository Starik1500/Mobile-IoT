import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_camera_plugin/my_camera_plugin.dart';
import 'dart:convert';

import '../providers/mqtt.dart';
import '../providers/connectivity_provider.dart';
import '../cubits/sensor/sensor_cubit.dart';
import '../cubits/sensor/sensor_state.dart';
import '../widgets/meter_info_card.dart';
import '../widgets/smart_data_card.dart';

class SensorScreen extends StatefulWidget {
  const SensorScreen({super.key});

  @override
  State<SensorScreen> createState() => _SensorScreenState();
}

class _SensorScreenState extends State<SensorScreen> {
  final TextEditingController _readingController = TextEditingController();
  String _meterType = 'electricity';
  bool _isInit = false;
  MqttProvider? _mqttProvider;

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
    _mqttProvider = context.read<MqttProvider>();

    if (!_isInit) {
      _meterType = ModalRoute.of(context)?.settings.arguments as String? ?? 'electricity';
      context.read<SensorCubit>().loadMeterData(_meterType);
      _isInit = true;
    }
  }

  @override
  void dispose() {
    _readingController.dispose();
    final mqtt = _mqttProvider;
    Future.microtask(() => mqtt?.disconnect());
    super.dispose();
  }

  void _saveRecord(String value, String source) {
    context.read<SensorCubit>().saveReading(_meterType, value, source);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Показники успішно збережено! ($source)'), backgroundColor: Colors.green)
    );
  }

  @override
  Widget build(BuildContext context) {
    final mqtt = context.watch<MqttProvider>();
    final hasInternet = context.watch<ConnectivityProvider>().hasInternet;

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
              width: double.infinity, color: Colors.red.shade400, padding: const EdgeInsets.symmetric(vertical: 8),
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
                  SmartDataCard(headerColor: headerColor, smartValue: smartValue, unit: unit, isConnected: mqtt.isConnected, onSave: () => _saveRecord(smartValue, 'Авто (MQTT)')),
                  const SizedBox(height: 24),
                  const Text('Передати вручну', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: TextField(
                              controller: _readingController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                  hintText: 'Введіть значення',
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.camera_alt, color: Colors.teal),
                                    onPressed: () async {
                                      FocusScope.of(context).unfocus();

                                      final String? photoBase64 = await MyCameraPlugin.openCamera(context);

                                      if (photoBase64 != null && context.mounted) {
                                        context.read<SensorCubit>().saveReading(
                                            _meterType,
                                            'Очікує модерації',
                                            'Фото (Вкладення)',
                                            photoBase64
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Фото відправлено на модерацію!'), backgroundColor: Colors.green)
                                        );
                                      }
                                    },
                                  )
                              )
                          )
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: headerColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20)),
                        onPressed: hasInternet ? () {
                          if (_readingController.text.isNotEmpty) {
                            _saveRecord(_readingController.text, 'Вручну');
                            _readingController.clear();
                            FocusScope.of(context).unfocus();
                          }
                        } : null,
                        child: const Text('ДОДАТИ'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text('Історія показників', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  BlocBuilder<SensorCubit, SensorState>(
                    builder: (context, state) {
                      if (state is SensorLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is SensorError) {
                        return Text(state.message, style: const TextStyle(color: Colors.red));
                      } else if (state is SensorLoaded) {
                        if (state.history.isEmpty) {
                          return const Padding(padding: EdgeInsets.all(16.0), child: Text('Історія порожня.', style: TextStyle(color: Colors.grey)));
                        }
                        return Column(
                          children: state.history.map((record) => Card(
                              elevation: 0, color: Colors.grey.shade50, margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                  leading: Icon(
                                      record['source'] == 'Фото (Вкладення)' ? Icons.image :
                                      (record['source'] == 'Вручну' ? Icons.edit_note : Icons.memory),
                                      color: Colors.grey
                                  ),
                                  title: Text(
                                      record['value'] == 'Очікує модерації' ? record['value']! : '${record['value']} $unit',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: record['value'] == 'Очікує модерації' ? Colors.orange : Colors.black
                                      )
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Джерело: ${record['source']}'),
                                      if (record.containsKey('image') && record['image'] != null && record['image']!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: GestureDetector(
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (BuildContext dialogContext) {
                                                  return Dialog(
                                                    backgroundColor: Colors.black,
                                                    insetPadding: EdgeInsets.zero,
                                                    child: Stack(
                                                      alignment: Alignment.center,
                                                      children: [
                                                        InteractiveViewer(
                                                          minScale: 1.0,
                                                          maxScale: 5.0,
                                                          child: Image.memory(
                                                            base64Decode(record['image']!),
                                                            fit: BoxFit.contain,
                                                          ),
                                                        ),
                                                        Positioned(
                                                          top: 40,
                                                          right: 16,
                                                          child: IconButton(
                                                            icon: const Icon(Icons.close, color: Colors.white, size: 32),
                                                            onPressed: () => Navigator.of(dialogContext).pop(),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.memory(
                                                base64Decode(record['image']!),
                                                height: 100,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Text(record['date']!)
                              )
                          )).toList(),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}