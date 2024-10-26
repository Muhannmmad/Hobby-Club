import 'package:flutter/material.dart';
import 'package:hoppy_club/features/home/repository/hobby.dart';
import 'package:hoppy_club/features/home/widgets/hobbies_card.dart';
import 'package:hoppy_club/shared/widgets/bottom.navigation.dart';

class HobbiesView extends StatelessWidget {
  const HobbiesView({
    super.key,
    required this.context,
  });

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hobbies'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Image.asset('assets/icons/3dgifmaker57572.gif',
                width: 100, height: 100),
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
          HobbiesCard(hobbies: indoorHobbies, context: context),
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
          HobbiesCard(hobbies: outdoorHobbies, context: context),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(selectedIndex: 0),
    );
  }
}
