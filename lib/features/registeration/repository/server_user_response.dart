import 'user.dart';

// Wenn sich der Nutzer einloggt, kann es passieren, dass er falsche
// Daten eingibt. Da wir also nicht nur einen User von unserer
// "fiktiven" Datenbank zurückbekommen, möchten wir auch eine Fehlermeldung speichern
// und prüfen, ob die Anfrage überhaupt erfolgreich war.
class ServerUserResponse {
  final User? user;
  final bool success;
  final String? errorMessage;

  ServerUserResponse({this.user, required this.success, this.errorMessage});
}
