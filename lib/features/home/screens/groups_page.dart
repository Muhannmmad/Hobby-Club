import 'package:flutter/material.dart';
import 'package:hoppy_club/features/home/repository/hobby.dart';

class GroupsPage extends StatelessWidget {
  final Hobby hobby;

  const GroupsPage({super.key, required this.hobby});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(hobby.name)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/rotat.gif'),
            Text(hobby.name, style: const TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}
