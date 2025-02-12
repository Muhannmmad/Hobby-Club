class User {
  final String email;
  final String password;
  final String name;
  final bool isAdmin;

  User({
    required this.email,
    required this.password,
    this.name = "User",
    this.isAdmin = false,
  });
}
