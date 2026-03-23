import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/auth_interface.dart';
import '../../data/hive_auth_repository.dart';
import '../../data/api_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());
  Future<void> checkAutoLogin() async {
    emit(AuthLoading());
    try {
      final user = await authRepository.getCurrentUser();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await apiRepository.syncUserData(email);

      if (user != null && user.password == password) {
        await authRepository.saveSession(email);
        final localUser = await authRepository.getCurrentUser();
        emit(AuthAuthenticated(localUser ?? user));
      } else {
        emit(AuthError('Невірний email або пароль!'));
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError('Помилка входу: $e'));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> register(User user) async {
    emit(AuthLoading());
    try {
      await authRepository.register(user);
      await authRepository.login(user.email, user.password);

      final loggedInUser = await authRepository.getCurrentUser();
      if (loggedInUser != null) {
        emit(AuthAuthenticated(loggedInUser));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> logout() async {
    emit(AuthLoading());
    await authRepository.logout();
    emit(AuthUnauthenticated());
  }

  Future<void> updateUser(User user) async {
    try {
      await authRepository.updateUser(user);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError('Помилка оновлення профілю'));
    }
  }
}