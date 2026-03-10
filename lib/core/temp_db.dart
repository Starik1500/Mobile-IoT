class FakeDB {
  static bool isLoggedIn = false;

  static Map<String, dynamic>? activeUser;

  static List<Map<String, dynamic>> savedAccounts = [];
}