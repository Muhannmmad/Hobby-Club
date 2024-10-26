import 'package:flutter/material.dart';
import 'package:hoppy_club/shared/screens/detailed_profile.dart';
import 'package:hoppy_club/features/profiles/repository/user.dart';
import 'package:hoppy_club/features/profiles/widgets/likes_remove.dart';

class ProfileCard extends StatelessWidget {
  final User user;

  const ProfileCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailedProfile(user: user),
          ),
        );
      },
      child: Card(
        elevation: 8.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Stack(
          alignment: Alignment.bottomLeft,
          children: [
            Image.asset(
              user.profileImage,
              fit: BoxFit.cover,
              height: 800,
              width: double.infinity,
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    "${user.firstName}, ${user.age}",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                    height: 80,
                  ),
                  Icon(
                    user.isOnline ? Icons.circle : Icons.circle_outlined,
                    color: user.isOnline ? Colors.green : Colors.red,
                    size: 10,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                user.city.toUpperCase(),
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
