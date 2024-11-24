import 'package:hoppy_club/features/registeration/repository/server_user_response.dart';
import 'package:hoppy_club/features/registeration/repository/user_repository.dart';

import 'mock_user_database.dart';

/// Hinweis: Wir nutzen eine fiktive Datenbank die unter /repositories/mock_user_database.dart definiert ist
class MockUserRepository implements UserRepository {
  @override
  Future<ServerUserResponse> loginAndGetUser(
      String email, String password) async {
    // 2 Sekunden warten, um eine Server-Abfrage zu simulieren.
    await Future.delayed(const Duration(seconds: 2));

    // Überprüfen, ob der User überhaupt in unserer Datenbank existiert.
    if (email.endsWith("@test.de")) {
      // Überprüfen, ob das Passwort korrekt ist.
      if (password == "123") {
        // Wenn der Nutzer sich mit einer normalen E-Mail angemeldet hat,
        // geben wir den normalen User zurück.
        final user = email.startsWith("test") ? normalUser : adminUser;

        // Eine erfolgreiche ServerUserResponse zurückgeben.
        return ServerUserResponse(success: true, user: user);
      } else {
        // Das Passwort ist falsch, und wir geben eine fehlgeschlagene ServerUserResponse zurück.
        return ServerUserResponse(
            success: false, errorMessage: "Password is invalid");
      }
    } else {
      // Die E-Mail, mit der sich der Nutzer angemeldet hat, existiert gar nicht in unserer
      // fiktiven Datenbank, und wir geben eine fehlgeschlagene ServerUserResponse zurück.
      return ServerUserResponse(success: false, errorMessage: "User not found");
    }
  }
}
