class Event {
  final String title;
  final String date;
  final String description;

  Event({
    required this.title,
    required this.date,
    required this.description,
  });
}

final List<Event> sampleEvents = [
  Event(
    title: 'Photography Meetup',
    date: 'Oct 30, 2024',
    description: 'Join us for a photography walk around the city.',
  ),
  Event(
    title: 'Hiking Adventure',
    date: 'Nov 5, 2024',
    description: 'A challenging yet rewarding hike up the mountains.',
  ),
  Event(
    title: 'Cycling Marathon',
    date: 'Nov 12, 2024',
    description: 'A cycling event for enthusiasts at all levels.',
  ),
];
