import 'package:flutter/material.dart';
import 'package:hoppy_club/likesRemoveChat.dart';
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    user.profileImage,
                    fit: BoxFit.cover,
                    height: 700,
                    width: double.infinity,
                  ),
                ),
                Positioned(
                  right: 0,
                  top: MediaQuery.of(context).size.height * 0.3,
                  child: ClipRRectButton(
                    onFavoritePressed: () {},
                    onChatPressed: () {},
                    onClosePressed: () {},
                    buttonSize: 60,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: const Color.fromARGB(255, 229, 211, 19),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user.firstName}, ${user.age}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'City: ${user.city}',
                        style: TextStyle(
                          fontSize: 20,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'About: ${user.about}',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Hobbies: ${user.hobbies.join(', ')}',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
