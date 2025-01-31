import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hoppy_club/features/home/widgets/hobbies_card.dart';
import 'package:hoppy_club/shared/widgets/bottom.navigation.dart';
import 'package:hoppy_club/features/home/repository/hobby.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0; // Track the selected index

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          const SizedBox(height: 70),
          Center(
            child: Text(
              'Hobby Club',
              style: GoogleFonts.spicyRice(
                textStyle: Theme.of(context).textTheme.displayLarge,
                fontSize: 48,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                color: const Color.fromARGB(205, 67, 7, 82),
              ),
            ),
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
          HobbiesCard(hobbies: indoorHobbies),
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
          HobbiesCard(hobbies: outdoorHobbies),
          const SizedBox(height: 30),
          const SizedBox(height: 20),
        ],
      ),
      bottomNavigationBar: BottomNavBar(selectedIndex: selectedIndex),
    );
  }
}
