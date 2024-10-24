import 'package:flutter/material.dart';
import 'package:hoppy_club/NewMachScreen.dart';
import 'package:hoppy_club/chatscreen.dart';
import 'package:hoppy_club/edit.profile.screen.dart';
import 'package:hoppy_club/features/shared/screens/bottom.navigation.dart';
import 'package:hoppy_club/hobby.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });

    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => NewMachesScreen()),
      );
    } else if (index == 2) {
      // Add the corresponding screen here.
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChatScreen()),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EditProfileScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hobbies')),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Image.asset('assets/rotat.gif', width: 100, height: 100),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text('Hobby Club',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple)),
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Indoor Hobbies',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          buildHobbyList(indoorHobbies, context),
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Outdoor Hobbies',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          buildHobbyList(outdoorHobbies, context),
        ],
      ),
      bottomNavigationBar: BottomNavBar(selectedIndex: 0),
    );
  }

  Widget buildHobbyList(List<Hobby> hobbies, BuildContext context) {
    return Container(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: hobbies.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => GroupPage(hobby: hobbies[index])),
              );
            },
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(10)),
                    child: Image.asset(
                      hobbies[index].image,
                      width: 160,
                      height: 160,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      hobbies[index].name,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class GroupPage extends StatelessWidget {
  final Hobby hobby;

  GroupPage({required this.hobby});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(hobby.name)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(hobby.image, width: 150, height: 150),
            const SizedBox(height: 20),
            Text(hobby.name, style: const TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}
