import 'package:hoppy_club/features/registeration/repository/server_user_response.dart';

// Vorlage/Template User Repository
abstract class UserRepository {
  Future<ServerUserResponse?> loginAndGetUser(String email, String password);
}
