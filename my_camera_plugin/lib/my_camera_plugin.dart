import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MyCameraPlugin {
  static const MethodChannel _channel = MethodChannel('my_camera_plugin');

  static Future<String?> openCamera(BuildContext context) async {
    if (Platform.isAndroid) {
      try {
        final String? base64Image = await _channel.invokeMethod('openCamera');
        return base64Image;
      } on PlatformException catch (e) {
        debugPrint("Помилка виклику камери: '${e.message}'.");
        return null;
      }
    } else {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Увага', style: TextStyle(color: Colors.red)),
            content: const Text('Цей функціонал підтримується лише на Android пристроях.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('ЗРОЗУМІЛО')),
            ],
          ),
        );
      }
      return null;
    }
  }
}