import 'package:flutter/material.dart';
import 'package:hoppy_club/new_mach_screen.dart';
import 'package:hoppy_club/chat_screen.dart';
import 'package:hoppy_club/config.dart';
import 'package:hoppy_club/edit_profile_screen.dart';
import 'package:hoppy_club/home_screen.dart';
import 'package:hoppy_club/swip_screen.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
  });

  void onItemTapped(BuildContext context, int index) {
    if (index == selectedIndex) return;

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Favorites()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SwipeScreen()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ChatScreen()),
      );
    } else if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const EditProfileScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: darkpurble,
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavItem(Icons.home, 'Home', 0, context),
            _buildNavItem(Icons.favorite, 'Favorites', 1, context),
            _buildNavItem(
                Icons.message, 'Messages', 3, context), // Updated this line
            _buildNavItem(Icons.search, 'Search', 2, context),
            _buildNavItem(Icons.person, 'Profile', 4, context),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, String label, int index, BuildContext context) {
    return GestureDetector(
      onTap: () => onItemTapped(context, index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: selectedIndex == index ? Colors.purple[400] : Colors.white,
          ),
          Text(
            label,
            style: TextStyle(
              color: selectedIndex == index ? Colors.purple[400] : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
