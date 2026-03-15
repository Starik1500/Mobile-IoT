class User {
  final String name;
  final String email;
  final String address;
  final String password;
  final List<String> meters;
  final String? avatarPath;

  const User({
    required this.name,
    required this.email,
    required this.address,
    required this.password,
    required this.meters,
    this.avatarPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'address': address,
      'password': password,
      'meters': meters,
      'avatarPath': avatarPath,
    };
  }

  factory User.fromMap(Map<dynamic, dynamic> map) {
    return User(
      name: map['name'] as String,
      email: map['email'] as String,
      address: map['address'] as String,
      password: map['password'] as String,
      meters: List<String>.from(map['meters'] ?? []),
      avatarPath: map['avatarPath'] as String?,
    );
  }
}

abstract class IAuthRepository {
  Future<void> register(User user);
  Future<User> login(String email, String password);
  Future<void> updateUser(User user);
  Future<void> logout();
  Future<User?> getCurrentUser();

  Future<void> addMeterHistory(String email, String meterType, Map<String, String> record);
  Future<List<Map<String, String>>> getMeterHistory(String email, String meterType);
}