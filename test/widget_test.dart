/*import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:hoppy_club/main.dart';
import 'package:hoppy_club/features/start/screens/start_screen.dart';
import 'package:hoppy_club/features/registeration/repository/mock_auth_repository.dart';
import 'package:hoppy_club/features/registeration/repository/database_repository.dart';

void main() {
  testWidgets('MyApp widget test', (WidgetTester tester) async {
    // Mock repositories
    final authRepository = MockAuthRepository();
    final databaseRepository = DatabaseRepository();

    // Mock the MyApp startup with StartScreen
    await tester.pumpWidget(
      MaterialApp(
        home: MyApp(
          startScreen: StartScreen(),
          authRepository: authRepository,
          databaseRepository: databaseRepository,
        ),
      ),
    );

    // Verify that "Hobby Club" appears on the StartScreen
    expect(find.text('Hobby Club'), findsOneWidget);
  });
}*/
