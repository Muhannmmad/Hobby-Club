import 'package:flutter/material.dart';
import 'package:hoppy_club/shared/widgets/bottom.navigation.dart';
import 'package:hoppy_club/shared/screens/detailed_profile.dart';
import 'package:hoppy_club/features/profiles/repository/user.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: Column(
        children: [
          buildStorySection(context),
          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return buildChat(context, user); // Call the buildChat method
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(selectedIndex: 3),
    );
  }

  Widget buildStorySection(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: users.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final user = users[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailedProfile(user: user),
                ),
              );
            },
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      backgroundImage: AssetImage(user.profileImage),
                      radius: 40,
                    ),
                    if (user.isOnline)
                      const Positioned(
                        bottom: 0,
                        right: -8,
                        child: CircleAvatar(
                          radius: 8,
                          backgroundColor: Colors.green,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  user.firstName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildChat(BuildContext context, User user) {
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
