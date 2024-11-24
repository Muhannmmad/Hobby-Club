import 'package:hoppy_club/features/home/repository/event_database_repository.dart';
import 'package:hoppy_club/features/home/repository/events.dart';

class MockEventDatabaseRepository implements EventDatabaseRepository {
  final List<Event> _mockEvents = [
    Event(
        title: 'Test Event 1',
        date: 'Dec 25, 2024',
        description: 'Mock Description 1'),
    Event(
        title: 'Test Event 2',
        date: 'Jan 1, 2025',
        description: 'Mock Description 2'),
  ];

  @override
  Future<List<Event>> fetchEvents() async {
    return Future.value(_mockEvents);
  }

  @override
  Future<void> addEvent(Event event) async {
    _mockEvents.add(event);
  }

  @override
  Future<void> deleteEvent(String title) async {
    _mockEvents.removeWhere((event) => event.title == title);
  }
}
