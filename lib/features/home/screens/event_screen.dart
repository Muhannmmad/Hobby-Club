import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hoppy_club/shared/widgets/bottom.navigation.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  EventScreenState createState() => EventScreenState();
}

class EventScreenState extends State<EventScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, String>> _getUserProfile(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (userDoc.exists && userDoc.data() != null) {
      final data = userDoc.data()!;
      return {
        'firstName': data['firstName'] ?? 'Unknown',
        'lastName': data['lastName'] ?? '',
      };
    }
    return {'firstName': 'Unknown', 'lastName': ''};
  }

  Future<void> _toggleJoinEvent(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userProfile = await _getUserProfile(user.uid);
    final userData = {
      'uid': user.uid,
      'firstName': userProfile['firstName']!,
      'lastName': userProfile['lastName']!,
    };

    final eventDoc = await _firestore.collection('events').doc(eventId).get();
    if (!eventDoc.exists) return;

    final joinedUsers = (eventDoc.data()?['joinedUsers'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        [];
    final isJoined = joinedUsers.any((u) => u['uid'] == user.uid);

    if (isJoined) {
      await _firestore.collection('events').doc(eventId).update({
        'joinedUsers': FieldValue.arrayRemove([userData]),
      });
    } else {
      await _firestore.collection('events').doc(eventId).update({
        'joinedUsers': FieldValue.arrayUnion([userData]),
      });
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    await _firestore.collection('events').doc(eventId).delete();
  }

  void _showEventDialog({String? eventId, Map<String, dynamic>? eventData}) {
    showDialog(
      context: context,
      builder: (context) => EventDialog(
        eventId: eventId,
        eventData: eventData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('events').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('No events available. Create one!'));
          }

          final events = snapshot.data!.docs;

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final data = event.data() as Map<String, dynamic>;
              final creatorUid = data['creatorUid'] ?? 'Unknown';

              // Fetch creator details
              final creatorNameFuture = _getUserProfile(creatorUid);

              final joinedUsers = (data['joinedUsers'] as List?)
                      ?.whereType<Map<String, dynamic>>()
                      .toList() ??
                  [];
              final currentUserId = currentUser?.uid;
              final isJoined = currentUserId != null &&
                  joinedUsers.any((user) => user['uid'] == currentUserId);

              final joinedUsersDisplay = joinedUsers.map((user) {
                return '${user['firstName']} ${user['lastName']}';
              }).join(', ');

              return FutureBuilder<Map<String, String>>(
                future: creatorNameFuture,
                builder: (context, snapshot) {
                  final creatorProfile = snapshot.data;
                  final creatorName = creatorProfile != null
                      ? '${creatorProfile['firstName']} ${creatorProfile['lastName']}'
                      : 'Fetching...';

                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text(data['name']),
                      subtitle: Text(
                        'Place: ${data['place']}\n'
                        'Date: ${data['date']} at ${data['time']}\n'
                        'Description: ${data['description']}\n'
                        'Created by: $creatorName\n'
                        'Joined: $joinedUsersDisplay',
                      ),
                      isThreeLine: true,
                      trailing: currentUserId == creatorUid
                          ? PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'Edit') {
                                  _showEventDialog(
                                      eventId: event.id, eventData: data);
                                } else if (value == 'Delete') {
                                  _deleteEvent(event.id);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                    value: 'Edit', child: Text('Edit')),
                                const PopupMenuItem(
                                    value: 'Delete', child: Text('Delete')),
                              ],
                            )
                          : ElevatedButton(
                              onPressed: () => _toggleJoinEvent(event.id),
                              child: Text(isJoined ? 'Leave' : 'Join'),
                            ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 40.0),
        child: ElevatedButton(
          onPressed: () => _showEventDialog(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple, // Button color
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: const Text(
            'Create new event',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(selectedIndex: 3),
    );
  }
}

class EventDialog extends StatefulWidget {
  final String? eventId;
  final Map<String, dynamic>? eventData;

  const EventDialog({super.key, this.eventId, this.eventData});

  @override
  _EventDialogState createState() => _EventDialogState();
}

class _EventDialogState extends State<EventDialog> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _place = '';
  String _date = '';
  String _time = '';
  String _description = '';

  @override
  void initState() {
    super.initState();
    if (widget.eventData != null) {
      _name = widget.eventData!['name'];
      _place = widget.eventData!['place'];
      _date = widget.eventData!['date'];
      _time = widget.eventData!['time'];
      _description = widget.eventData!['description'];
    }
  }

  Future<void> _saveEvent() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final eventData = {
        'name': _name,
        'place': _place,
        'date': _date,
        'time': _time,
        'description': _description,
        'creatorUid': user.uid,
        'creatorName': user.displayName ?? 'Anonymous',
        'joinedUsers': [],
      };

      if (widget.eventId == null) {
        await FirebaseFirestore.instance.collection('events').add(eventData);
      } else {
        await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.eventId)
            .update(eventData);
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.eventId == null ? 'Create Event' : 'Edit Event'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Event Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a name' : null,
                onSaved: (value) => _name = value!,
              ),
              TextFormField(
                initialValue: _place,
                decoration: const InputDecoration(labelText: 'Place'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a place' : null,
                onSaved: (value) => _place = value!,
              ),
              TextFormField(
                initialValue: _date,
                decoration: const InputDecoration(labelText: 'Date'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a date' : null,
                onSaved: (value) => _date = value!,
              ),
              TextFormField(
                initialValue: _time,
                decoration: const InputDecoration(labelText: 'Time'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a time' : null,
                onSaved: (value) => _time = value!,
              ),
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a description' : null,
                onSaved: (value) => _description = value!,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveEvent,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
