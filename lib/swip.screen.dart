import 'package:flutter/material.dart';
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
  _SwipeScreenState createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  List<User> userList = users;
  int currentIndex = 0;
  int _selectedIndex = 0; // Track selected BottomNavigationBar item

  // Swipe logic
  void _swipeRight() {
    setState(() {
      if (currentIndex < userList.length - 1) {
        currentIndex++;
      }
    });
  }

  void _swipeLeft() {
    setState(() {
      if (currentIndex > 0) {
        currentIndex--;
      }
    });
  }

  // Handle BottomNavigationBar tap
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update the selected index on tap
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
                title: Text('New Matches'),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              Expanded(
                child: GestureDetector(
                  onHorizontalDragEnd: (DragEndDetails details) {
                    if (details.primaryVelocity! > 0) {
                      _swipeLeft();
                    } else if (details.primaryVelocity! < 0) {
                      _swipeRight();
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
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '',
          ),
        ],
        currentIndex: _selectedIndex, // Bind the selected index
        selectedItemColor: Colors.purple[400],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped, // Handle the tap event
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
    );
  }
}
