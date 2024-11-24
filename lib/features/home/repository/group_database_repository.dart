import 'package:hoppy_club/features/home/repository/hobby.dart';

abstract class GroupDatabaseRepository {
  Future<List<Hobby>> fetchGroups();
  Future<void> addGroup(Hobby hobby);
  Future<void> deleteGroup(String name);
}
