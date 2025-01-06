import 'package:flutter/material.dart';
import 'package:hoppy_club/features/profiles/widgets/likes_remove.dart';
import 'package:hoppy_club/features/profiles/repository/user_profile.dart';

class DetailedProfile extends StatelessWidget {
  final User user;

  const DetailedProfile({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Fetch screen size
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

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
                  child: AspectRatio(
                    aspectRatio: isTablet ? 16 / 9 : 4 / 3,
                    child: Image.asset(
                      user.profileImage,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  top: screenSize.height * 0.25,
                  child: ClipRRectButton(
                    onFavoritePressed: () {},
                    onChatPressed: () {},
                    onClosePressed: () {},
                    buttonSize: isTablet ? 80 : 60,
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
                color: const Color.fromARGB(255, 226, 195, 231),
                child: Padding(
                  padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user.firstName}, ${user.age}',
                        style: TextStyle(
                          fontSize: isTablet ? 28 : 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'City: ${user.city}',
                        style: TextStyle(
                          fontSize: isTablet ? 22 : 20,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'About: ${user.about}',
                        style: TextStyle(fontSize: isTablet ? 18 : 16),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Hobbies: ${user.hobbies.join(', ')}',
                        style: TextStyle(fontSize: isTablet ? 18 : 16),
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
