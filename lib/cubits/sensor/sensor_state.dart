abstract class SensorState {}

class SensorLoading extends SensorState {}

class SensorLoaded extends SensorState {
  final List<Map<String, String>> history;
  SensorLoaded(this.history);
}

class SensorError extends SensorState {
  final String message;
  SensorError(this.message);
}