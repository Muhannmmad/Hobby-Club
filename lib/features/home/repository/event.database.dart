import 'package:hoppy_club/features/home/repository/events.dart';

abstract class DatabaseRepository {
  Future<List<Event>> getEvents();
  Future<void> addEvent(Event event);
  Future<void> deleteEvent(String title);
  Future<void> updateEvent(Event event);
}
