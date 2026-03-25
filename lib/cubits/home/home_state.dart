import '../../domain/auth_interface.dart';

abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final User user;
  final Map<String, String> readings;

  HomeLoaded(this.user, this.readings);
}

class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
}