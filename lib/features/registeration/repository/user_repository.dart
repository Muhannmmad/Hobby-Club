import 'server_user_response.dart';

abstract class UserRepository {
  Future<ServerUserResponse> loginAndGetUser(String email, String password);
  Future<ServerUserResponse> registerUser(String email, String password);
}
