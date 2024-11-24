import 'package:hoppy_club/features/home/repository/events.dart';

abstract class EventDatabaseRepository {
  Future<List<Event>> fetchEvents();
  Future<void> addEvent(Event event);
  Future<void> deleteEvent(String title);
}
