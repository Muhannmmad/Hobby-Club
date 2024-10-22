import 'package:flutter/material.dart';
import 'package:hoppy_club/user.dart';

class DetailedProfile extends StatelessWidget {
  final User user;

  DetailedProfile({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${user.firstName} ${user.lastName}'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(user.profileImage,
              fit: BoxFit.cover, height: 500, width: double.infinity),
          SizedBox(height: 20),
          Text(
            '${user.firstName}, ${user.age}',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            'City: ${user.city}',
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(height: 20),
          Text('About: ${user.about}', style: TextStyle(fontSize: 16)),
          SizedBox(height: 20),
          Text(
            'Hobbies: ${user.hobbies.join(', ')}',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
