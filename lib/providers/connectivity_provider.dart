import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityProvider with ChangeNotifier {
  bool _hasInternet = true;
  bool get hasInternet => _hasInternet;

  ConnectivityProvider() {
    _init();
  }

  void _init() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      bool isConnected = !results.contains(ConnectivityResult.none);

      if (_hasInternet != isConnected) {
        _hasInternet = isConnected;
        notifyListeners();
      }
    });
  }

  Future<bool> checkConnectionNow() async {
    final results = await Connectivity().checkConnectivity();
    _hasInternet = !results.contains(ConnectivityResult.none);
    notifyListeners();
    return _hasInternet;
  }
}