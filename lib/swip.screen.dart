import 'package:flutter/material.dart';
import 'package:hoppy_club/features/shared/screens/bottom.navigation.dart';
import 'package:hoppy_club/profile.card.dart';
import 'user.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SwipeScreen(),
    );
  }
}

class SwipeScreen extends StatefulWidget {
  @override
  SwipeScreenState createState() => SwipeScreenState();
}

class SwipeScreenState extends State<SwipeScreen> {
  List<User> userList = users;
  int currentIndex = 0;
  int selectedIndex = 0;

  void swipeRight() {
    setState(() {
      if (currentIndex < userList.length - 1) {
        currentIndex++;
      }
    });
  }

  void swipeLeft() {
    setState(() {
      if (currentIndex > 0) {
        currentIndex--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/b3.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              AppBar(
                title: const Text('New Matches'),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              Expanded(
                child: GestureDetector(
                  onHorizontalDragEnd: (DragEndDetails details) {
                    if (details.primaryVelocity! > 0) {
                      swipeLeft();
                    } else if (details.primaryVelocity! < 0) {
                      swipeRight();
                    }
                  },
                  child: Center(
                    child: ProfileCard(user: userList[currentIndex]),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(selectedIndex: 2),
    );
  }
}
