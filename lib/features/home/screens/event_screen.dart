import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  EventScreenState createState() => EventScreenState();
}

class EventScreenState extends State<EventScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _updateEventStatus(String eventId, String status) async {
    await _firestore.collection('events').doc(eventId).update({
      'status': status,
    });
  }

  Future<void> _deleteEvent(String eventId) async {
    await _firestore.collection('events').doc(eventId).delete();
  }

  @override
  Widget build(BuildContext context) {
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
          final currentUser = _auth.currentUser;

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final data = event.data() as Map<String, dynamic>;
              final creatorUid = data['creatorUid'] ?? 'Unknown';
              final creatorName = data['creatorName'] ?? 'Unknown';
              final isCreator = currentUser?.uid == creatorUid;

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(data['name']),
                  subtitle: Text(
                      'Place: ${data['place']}\nDate: ${data['date']} at ${data['time']}\nDescription: ${data['description']}\nCreated by: $creatorName'),
                  isThreeLine: true,
                  trailing: isCreator
                      ? PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'Edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditEventScreen(
                                    eventId: event.id,
                                    initialData: data,
                                  ),
                                ),
                              );
                            } else if (value == 'Delete') {
                              _deleteEvent(event.id);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'Edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'Delete',
                              child: Text('Delete'),
                            ),
                          ],
                        )
                      : DropdownButton<String>(
                          value: data['status'] ?? 'Join',
                          items: const [
                            DropdownMenuItem(
                                value: 'Join', child: Text('Join')),
                            DropdownMenuItem(
                                value: 'Maybe', child: Text('Maybe')),
                            DropdownMenuItem(
                                value: 'Not Interested',
                                child: Text('Not Interested')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              _updateEventStatus(event.id, value);
                            }
                          },
                        ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateEventScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class EditEventScreen extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> initialData;

  const EditEventScreen({
    required this.eventId,
    required this.initialData,
    super.key,
  });

  @override
  EditEventScreenState createState() => EditEventScreenState();
}

class EditEventScreenState extends State<EditEventScreen> {
  late TextEditingController _nameController;
  late TextEditingController _placeController;
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late TextEditingController _descriptionController;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData['name']);
    _placeController = TextEditingController(text: widget.initialData['place']);
    _dateController = TextEditingController(text: widget.initialData['date']);
    _timeController = TextEditingController(text: widget.initialData['time']);
    _descriptionController =
        TextEditingController(text: widget.initialData['description']);
  }

  Future<void> _updateEvent() async {
    await _firestore.collection('events').doc(widget.eventId).update({
      'name': _nameController.text,
      'place': _placeController.text,
      'date': _dateController.text,
      'time': _timeController.text,
      'description': _descriptionController.text,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Event')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Event Name'),
            ),
            TextField(
              controller: _placeController,
              decoration: const InputDecoration(labelText: 'Event Place'),
            ),
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(labelText: 'Event Date'),
            ),
            TextField(
              controller: _timeController,
              decoration: const InputDecoration(labelText: 'Event Time'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Event Description'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateEvent,
              child: const Text('Update Event'),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  CreateEventScreenState createState() => CreateEventScreenState();
}

class CreateEventScreenState extends State<CreateEventScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _submitEvent() async {
    final user = _auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to create events')),
      );
      return;
    }

    final String name = _nameController.text;
    final String place = _placeController.text;
    final String date = _dateController.text;
    final String time = _timeController.text;
    final String description = _descriptionController.text;

    if (name.isNotEmpty &&
        place.isNotEmpty &&
        date.isNotEmpty &&
        time.isNotEmpty &&
        description.isNotEmpty) {
      await _firestore.collection('events').add({
        'name': name,
        'place': place,
        'date': date,
        'time': time,
        'description': description,
        'creatorUid': user.uid,
        'creatorName': user.displayName ?? 'Anonymous',
        'status': 'Join', // Default status
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Event Name'),
            ),
            TextField(
              controller: _placeController,
              decoration: const InputDecoration(labelText: 'Event Place'),
            ),
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(labelText: 'Event Date'),
            ),
            TextField(
              controller: _timeController,
              decoration: const InputDecoration(labelText: 'Event Time'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Event Description'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitEvent,
              child: const Text('Create Event'),
            ),
          ],
        ),
      ),
    );
  }
}
