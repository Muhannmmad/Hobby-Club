import 'package:flutter/material.dart';
import 'package:hoppy_club/features/registeration/repository/mock_user_repository.dart';
import 'package:hoppy_club/features/registeration/repository/server_user_response.dart';

class UserService {
  // Wir benötigen den E-Mail-Controller, um die Eingabe der E-Mail zu empfangen.
  final emailController = TextEditingController();

  // Wir benötigen den Passwort-Controller, um die Eingabe des Passworts zu empfangen.
  final passwordController = TextEditingController();

  // Unser MockUserRepository, das die Abfrage eines Nutzers simuliert, sobald
  // wir uns einloggen. Hier könnte man die Abfrage des Nutzers und das Einloggen
  // in zwei Repositories/Module aufteilen.
  final _mockUserRepository = MockUserRepository();

  // Hier werden die E-Mail und das Passwort abgerufen, und die "login"-Methode
  // im mockUserRepository ausgeführt.
  Future<ServerUserResponse> login() {
    final email = emailController.text;
    final password = passwordController.text;
    return _mockUserRepository.loginAndGetUser(email, password);
  }
}
