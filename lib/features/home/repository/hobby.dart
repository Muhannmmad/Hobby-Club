class Hobby {
  final String name;
  final String image;
  final String groupId; // Added groupId field

  Hobby({
    required this.name,
    required this.image,
    required this.groupId, // Ensure groupId is initialized
  });
}

// Updated lists with groupId
final List<Hobby> indoorHobbies = [
  Hobby(
      name: 'Computer Games',
      image: 'assets/hobbies/computer games.jpg',
      groupId: 'group_1'),
  Hobby(name: 'Chess', image: 'assets/hobbies/chess.jpg', groupId: 'group_2'),
  Hobby(
      name: 'Cooking', image: 'assets/hobbies/cooking.jpg', groupId: 'group_3'),
  Hobby(
      name: 'Drawing', image: 'assets/hobbies/drawing.jpg', groupId: 'group_4'),
  Hobby(
      name: 'Reading', image: 'assets/hobbies/reading.jpg', groupId: 'group_5'),
];

final List<Hobby> outdoorHobbies = [
  Hobby(name: 'Sports', image: 'assets/hobbies/sports.jpg', groupId: 'group_6'),
  Hobby(name: 'Hiking', image: 'assets/hobbies/hiking.jpg', groupId: 'group_7'),
  Hobby(
      name: 'Cycling', image: 'assets/hobbies/cycling.jpg', groupId: 'group_8'),
  Hobby(
      name: 'Photography',
      image: 'assets/hobbies/photography.jpg',
      groupId: 'group_9'),
  Hobby(
      name: 'Camping',
      image: 'assets/hobbies/camping.jpg',
      groupId: 'group_10'),
];
