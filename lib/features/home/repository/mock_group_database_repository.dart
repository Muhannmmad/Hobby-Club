import 'package:hoppy_club/features/home/repository/group_database_repository.dart';
import 'package:hoppy_club/features/home/repository/hobby.dart';

class MockGroupDatabaseRepository implements GroupDatabaseRepository {
  final List<Hobby> _mockGroups = [
    Hobby(name: 'Mock Group 1', image: 'assets/mock_image_1.jpg'),
    Hobby(name: 'Mock Group 2', image: 'assets/mock_image_2.jpg'),
  ];

  @override
  Future<List<Hobby>> fetchGroups() async {
    return Future.value(_mockGroups);
  }

  @override
  Future<void> addGroup(Hobby hobby) async {
    _mockGroups.add(hobby);
  }

  @override
  Future<void> deleteGroup(String name) async {
    _mockGroups.removeWhere((group) => group.name == name);
  }
}
