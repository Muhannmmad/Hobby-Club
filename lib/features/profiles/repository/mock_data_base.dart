import 'package:hoppy_club/features/profiles/repository/datad_base_reprository.dart';
import 'user_profile.dart';

class MockDatabase implements DatabaseRepository {
  final List<User> _users = [];

  @override
  Future<List<User>> getUsers() async {
    await Future.delayed(const Duration(milliseconds: 100)); // Simulation
    return List.unmodifiable(_users);
  }

  @override
  Future<void> addUser(User user) async {
    // Verhindere Duplikate basierend auf Vor- und Nachnamen
    if (!_users.any(
        (u) => u.firstName == user.firstName && u.lastName == user.lastName)) {
      _users.add(user);
    }
  }

  @override
  Future<void> deleteUser(String firstName, String lastName) async {
    _users
        .removeWhere((u) => u.firstName == firstName && u.lastName == lastName);
  }

  @override
  Future<void> updateUser(User user) async {
    final index = _users.indexWhere(
        (u) => u.firstName == user.firstName && u.lastName == user.lastName);
    if (index != -1) {
      _users[index] = user;
    }
  }
}
