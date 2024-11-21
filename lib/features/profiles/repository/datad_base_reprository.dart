import 'package:hoppy_club/features/profiles/repository/user.dart';

abstract class DatabaseRepository {
  Future<List<User>> getUsers();
  Future<void> addUser(User user);
  Future<void> deleteUser(String firstName, String lastName);
  Future<void> updateUser(User user);
}
