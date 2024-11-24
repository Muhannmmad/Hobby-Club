import 'package:flutter/material.dart';
import 'package:hoppy_club/features/home/repository/events.dart';
import 'package:hoppy_club/features/home/repository/hobby.dart';
import 'package:hoppy_club/features/profiles/repository/user_profile.dart';
import 'package:hoppy_club/features/profiles/screens/new_mach_screen.dart';
import 'package:hoppy_club/shared/screens/detailed_profile.dart';

class GroupsPage extends StatelessWidget {
  final Hobby hobby;

  const GroupsPage({super.key, required this.hobby});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(hobby.name),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Members'),
              Tab(text: 'Chat'),
              Tab(text: 'Events'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            MembersTab(),
            ChatTab(),
            EventsTab(),
          ],
        ),
      ),
    );
  }
}

class MembersTab extends StatelessWidget {
  const MembersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8.0,
            crossAxisSpacing: 8.0,
            childAspectRatio: 0.7,
          ),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailedProfile(user: user),
                  ),
                );
              },
              child: UserCard(user: user),
            );
          },
        ),
      ),
    );
  }
}

class ChatTab extends StatelessWidget {
  const ChatTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: const [
              ListTile(title: Text('Sara: Hello!')),
              ListTile(title: Text('Lukas: Hi there!')),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              const Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class EventsTab extends StatelessWidget {
  const EventsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: sampleEvents.length,
      itemBuilder: (context, index) {
        final event = sampleEvents[index];
        return ListTile(
          title: Text(event.title),
          subtitle: Text('${event.date} - ${event.description}'),
        );
      },
    );
  }
}
