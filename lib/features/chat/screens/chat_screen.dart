import 'package:flutter/material.dart';
import 'package:hoppy_club/features/chat/widgets/down_card.dart';
import 'package:hoppy_club/features/chat/widgets/above_card.dart';
import 'package:hoppy_club/shared/widgets/bottom.navigation.dart';
import 'package:hoppy_club/features/profiles/repository/user_profile.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: Column(
        children: [
          AboveCard(context: context),
          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return DownCard(
                    context: context, user: user); // Call the buildChat method
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(selectedIndex: 3),
    );
  }
}
