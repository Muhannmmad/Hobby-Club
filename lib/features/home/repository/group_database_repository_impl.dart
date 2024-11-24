import 'package:hoppy_club/features/home/repository/group_database_repository.dart';
import 'package:hoppy_club/features/home/repository/hobby.dart';

class GroupDatabaseRepositoryImpl implements GroupDatabaseRepository {
  final List<Hobby> _groups = [];

  @override
  Future<List<Hobby>> fetchGroups() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List<Hobby>.from(_groups);
  }

  @override
  Future<void> addGroup(Hobby hobby) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _groups.add(hobby);
  }

  @override
  Future<void> deleteGroup(String name) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _groups.removeWhere((group) => group.name == name);
  }
}
