import 'package:flutter/material.dart';
import 'package:hoppy_club/features/profiles/repository/user.dart';
import 'package:hoppy_club/shared/screens/detailed_profile.dart';

class DownCard extends StatelessWidget {
  const DownCard({
    super.key,
    required this.context,
    required this.user,
  });

  final BuildContext context;
  final User user;

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
      child: ListTile(
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              backgroundImage: AssetImage(user.profileImage),
              radius: 25,
            ),
            if (user.isOnline)
              const Positioned(
                bottom: -6,
                right: -7,
                child: CircleAvatar(
                  radius: 6,
                  backgroundColor: Colors.green,
                ),
              ),
          ],
        ),
        title: Text(
          user.firstName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          'tomorrow we will meet again I will call you and arrange',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('7:00 pm'),
            Icon(Icons.check, size: 16),
          ],
        ),
      ),
    );
  }
}
