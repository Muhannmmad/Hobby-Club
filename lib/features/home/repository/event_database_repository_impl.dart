import 'package:hoppy_club/features/home/repository/event_database_repository.dart';
import 'package:hoppy_club/features/home/repository/events.dart';

class EventDatabaseRepositoryImpl implements EventDatabaseRepository {
  final List<Event> _events = [];

  @override
  Future<List<Event>> fetchEvents() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List<Event>.from(_events);
  }

  @override
  Future<void> addEvent(Event event) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _events.add(event);
  }

  @override
  Future<void> deleteEvent(String title) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _events.removeWhere((event) => event.title == title);
  }
}
