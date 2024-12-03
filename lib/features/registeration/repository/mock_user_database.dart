import 'user.dart';

// Mock Users
final User normalUser = User(
  email: "test@test.de",
  password: "123",
  name: "Test",
  isAdmin: false,
);

final User adminUser = User(
  email: "admin@test.de",
  password: "123",
  name: "AdminTest",
  isAdmin: true,
);
