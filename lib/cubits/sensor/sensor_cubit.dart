import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'sensor_state.dart';
import '../../data/hive_auth_repository.dart';

class SensorCubit extends Cubit<SensorState> {
  SensorCubit() : super(SensorLoading());

  Future<void> loadMeterData(String meterType) async {
    emit(SensorLoading());
    try {
      final user = await authRepository.getCurrentUser();
      if (user != null) {
        final history = await authRepository.getMeterHistory(user.email, meterType);
        emit(SensorLoaded(history));
      } else {
        emit(SensorError('Користувача не знайдено'));
      }
    } catch (e) {
      emit(SensorError('Помилка завантаження історії: $e'));
    }
  }

  Future<void> saveReading(String meterType, String value, String source) async {
    try {
      final user = await authRepository.getCurrentUser();
      if (user != null) {
        final date = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now());

        await authRepository.addMeterHistory(user.email, meterType, {
          'date': date,
          'value': value,
          'source': source
        });

        await loadMeterData(meterType);
      }
    } catch (e) {
      emit(SensorError('Помилка збереження: $e'));
    }
  }
}