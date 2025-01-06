import 'package:flutter/material.dart';
import 'package:hoppy_club/features/profiles/widgets/likes_remove.dart';
import 'package:hoppy_club/shared/screens/detailed_profile.dart';
import 'package:hoppy_club/shared/widgets/bottom.navigation.dart';
import 'package:hoppy_club/features/profiles/repository/user_profile.dart';

class Favorites extends StatelessWidget {
  const Favorites({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        backgroundColor: Colors.purple,
        elevation: 4.0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8.0,
            crossAxisSpacing: 8.0,
            childAspectRatio: 0.7,
          ),
          itemCount: users.length,
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
              child: UserCard(user: user),
            );
          },
        ),
      ),
      bottomNavigationBar: const BottomNavBar(selectedIndex: 1),
    );
  }
}

class UserCard extends StatelessWidget {
  final User user;

  const UserCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15.0),
                    topRight: Radius.circular(15.0),
                  ),
                  child: user.profileImage.isNotEmpty
                      ? Image.network(
                          user.profileImage,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 100),
                        )
                      : const Icon(
                          Icons.person,
                          size: 100,
                          color: Colors.grey,
                        ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: ClipRRectButton(
                    onFavoritePressed: () {
                      // Handle favorite action
                      debugPrint(
                          "Favorite button pressed for ${user.firstName}");
                    },
                    onChatPressed: () {
                      // Handle chat action
                      debugPrint("Chat button pressed for ${user.firstName}");
                    },
                    onClosePressed: () {
                      // Handle remove from favorites
                      debugPrint("Remove button pressed for ${user.firstName}");
                    },
                    buttonSize: 30, // Smaller button size for Favorites screen
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.firstName}, ${user.age}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  user.city,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    Icon(
                      user.isOnline ? Icons.circle : Icons.circle_outlined,
                      color: user.isOnline ? Colors.green : Colors.red,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user.isOnline ? 'Online' : 'Offline',
                      style: const TextStyle(
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
