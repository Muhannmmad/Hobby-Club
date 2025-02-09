import 'package:flutter/material.dart';
import 'package:hoppy_club/chat_room.dart';
import 'package:hoppy_club/features/profiles/screens/swipe_profile_screen.dart';
import 'package:hoppy_club/features/profiles/screens/my_profile_screen.dart';
import 'package:hoppy_club/features/profiles/screens/favorite_screen.dart';
import 'package:hoppy_club/config/config.dart';
import 'package:hoppy_club/features/home/screens/home_screen.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
  });

  void onItemTapped(BuildContext context, int index) {
    if (index == selectedIndex) return;

    Widget nextScreen;
    switch (index) {
      case 0:
        nextScreen = const HomeScreen();
        break;
      case 1:
        nextScreen = const FavoritesScreen();
        break;
      case 2:
        nextScreen = const SwipeableProfilesScreen();
        break;
      case 3:
        nextScreen = const ChatRoomScreen();
        break;
      case 4:
        nextScreen = const MyProfileScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    // Dynamically scale sizes based on screen width
    final double iconSize = (screenWidth * 0.07).clamp(24.0, 32.0);
    final double textSize = (screenWidth * 0.01).clamp(10.0, 14.0);
    final double navBarHeight = (screenHeight * 0.08).clamp(50.0, 80.0);

    return BottomAppBar(
      color: const Color.fromARGB(252, 0, 3, 0),
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: Container(
        height: navBarHeight,
        decoration: BoxDecoration(
          color: const Color.fromARGB(245, 61, 4, 75),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: lightpurble,
              spreadRadius: 2,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                    Icons.home, 'Home', 0, context, iconSize, textSize),
                _buildNavItem(Icons.favorite, 'Favorites', 1, context, iconSize,
                    textSize),
                _buildNavItem(
                    Icons.search, 'Search', 2, context, iconSize, textSize),
                _buildNavItem(
                    Icons.chat_bubble, 'Chat', 3, context, iconSize, textSize),
                _buildNavItem(
                    Icons.person, 'Profile', 4, context, iconSize, textSize),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index,
      BuildContext context, double iconSize, double textSize) {
    return GestureDetector(
      onTap: () => onItemTapped(context, index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: iconSize, // Dynamically scaled size
            color: selectedIndex == index ? Colors.purple[400] : Colors.white,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: textSize, // Dynamically scaled text size
              fontWeight: FontWeight.w500,
              color: selectedIndex == index ? Colors.purple[400] : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
