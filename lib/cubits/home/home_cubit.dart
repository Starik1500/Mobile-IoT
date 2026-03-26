import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_state.dart';
import '../../data/hive_auth_repository.dart';
import '../../data/api_repository.dart';
import '../../domain/auth_interface.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());

  Future<void> loadData() async {
    emit(HomeLoading());
    try {
      await authRepository.syncUnsavedProfiles();
      await authRepository.syncUnsavedData();

      final localUser = await authRepository.getCurrentUser();
      if (localUser == null) {
        emit(HomeError('Користувача не знайдено'));
        return;
      }

      final user = await apiRepository.syncUserData(localUser.email) ?? localUser;

      final Map<String, String> readings = {};
      for (String meter in user.meters) {
        final history = await authRepository.getMeterHistory(user.email, meter);
        String displayValue = 'Немає даних';

        if (history.isNotEmpty) {
          try {
            final validRecord = history.firstWhere((r) => r['value'] != 'Очікує модерації');
            displayValue = validRecord['value'].toString();
          } catch (e) {
            displayValue = '0';
          }
        }

        readings[meter] = displayValue;
      }

      emit(HomeLoaded(user, readings));
    } catch (e) {
      emit(HomeError('Помилка завантаження даних: $e'));
    }
  }

  Future<void> deleteMeter(User user, int index) async {
    final newMeters = List<String>.from(user.meters)..removeAt(index);
    final updatedUser = User(
      name: user.name, email: user.email, address: user.address,
      password: user.password, meters: newMeters, avatarPath: user.avatarPath,
    );

    await authRepository.updateUser(updatedUser);
    await loadData();
  }
}