class DatabaseRepository {
  Future<String> fetchData() async {
    await Future.delayed(const Duration(seconds: 1));
    return 'Data fetched from DatabaseRepository';
  }
}
