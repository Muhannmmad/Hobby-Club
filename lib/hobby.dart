class Hobby {
  final String name;
  final String image;

  Hobby({required this.name, required this.image});
}

final List<Hobby> indoorHobbies = [
  Hobby(name: 'Computer Games', image: 'assets/hobbies/computer games.jpg'),
  Hobby(name: 'Chess', image: 'assets/hobbies/chess.jpg'),
  Hobby(name: 'Cooking', image: 'assets/hobbies/cooking.jpg'),
  Hobby(name: 'Drawing', image: 'assets/hobbies/drawing.jpg'),
  Hobby(name: 'Reading', image: 'assets/hobbies/reading.jpg'),
];

final List<Hobby> outdoorHobbies = [
  Hobby(name: 'Sports', image: 'assets/hobbies/sports.jpg'),
  Hobby(name: 'Hiking', image: 'assets/hobbies/hiking.jpg'),
  Hobby(name: 'Cycling', image: 'assets/hobbies/cycling.jpg'),
  Hobby(name: 'Photography', image: 'assets/hobbies/photography.jpg'),
];
