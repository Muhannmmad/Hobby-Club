import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hoppy_club/features/home/screens/detailed_profile_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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

    return Stack(
      children: [
        // Background Image
        Positioned.fill(
          child: Image.asset(
            'assets/event.jpg', // Change to your image path
            fit: BoxFit.cover, // Adjusts the image to cover the screen
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: const Text('Join & Creat'),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('events')
                .where('endsAt',
                    isGreaterThan: Timestamp.now()) // Only fetch future events
                .snapshots(),
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
                  final Timestamp? createdAtTimestamp =
                      data['createdAt'] as Timestamp?;
                  final String createdAt = createdAtTimestamp != null
                      ? DateFormat('dd-MM-yyyy HH:mm')
                          .format(createdAtTimestamp.toDate())
                      : 'Unknown';

                  // Fetch creator details
                  final creatorNameFuture = _getUserProfile(creatorUid);

                  final joinedUsers = (data['joinedUsers'] as List?)
                          ?.whereType<Map<String, dynamic>>()
                          .toList() ??
                      [];
                  final currentUserId = currentUser?.uid;
                  final isJoined = currentUserId != null &&
                      joinedUsers.any((user) => user['uid'] == currentUserId);

                  joinedUsers.map((user) {
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
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['name'] ?? 'Unknown Event',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                          color: Colors.black, fontSize: 15),
                                      children: [
                                        const TextSpan(
                                          text: 'Place: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                        TextSpan(
                                            text:
                                                '${data['place'] ?? 'Unknown'}\n'),
                                        const TextSpan(
                                          text: 'Starts at: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                        TextSpan(
                                          text: data['startAt'] != null
                                              ? DateFormat('dd-MM-yyyy HH:mm')
                                                  .format((data['startAt']
                                                          as Timestamp)
                                                      .toDate())
                                              : 'N/A',
                                        ),
                                        const TextSpan(
                                          text: '\nEnds at: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                        TextSpan(
                                          text: data['endsAt'] != null
                                              ? DateFormat('dd-MM-yyyy HH:mm')
                                                  .format((data['endsAt']
                                                          as Timestamp)
                                                      .toDate())
                                              : 'N/A',
                                        ),
                                        const TextSpan(
                                          text: '\nDescription: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                        TextSpan(
                                            text:
                                                '${data['description'] ?? 'No description'}\n'),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // Created by section
                                  Row(
                                    children: [
                                      const Text(
                                        'Created by: ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              Color.fromARGB(255, 189, 36, 223),
                                          fontSize: 14,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  DetailedProfilePage(
                                                      userId: creatorUid),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          creatorName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color.fromARGB(
                                                255, 129, 4, 246),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'At: $createdAt',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // Joined users section (Scrollable Box)
                                  const Text(
                                    'Joined by:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color.fromARGB(255, 189, 36, 223),
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      border:
                                          Border.all(color: Colors.blueAccent),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    constraints: const BoxConstraints(
                                      maxHeight:
                                          200, // Scrollable when too many users
                                      minWidth: double.infinity,
                                    ),
                                    child: SingleChildScrollView(
                                      child: Wrap(
                                        children:
                                            joinedUsers.map<Widget>((user) {
                                          String? userId =
                                              user['uid']?.toString();
                                          String userName =
                                              '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'
                                                  .trim();

                                          return GestureDetector(
                                            onTap: () {
                                              if (userId != null &&
                                                  userId.isNotEmpty) {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        DetailedProfilePage(
                                                            userId: userId),
                                                  ),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          'User profile not available')),
                                                );
                                              }
                                            },
                                            child: Text(
                                              '$userName, ',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blueAccent,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Moved the Join/Joined Button to the Top Right
                            Positioned(
                              top: 30,
                              right: 8,
                              child: currentUserId == creatorUid
                                  ? PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'Edit') {
                                          _showEventDialog(
                                              eventId: event.id,
                                              eventData: data);
                                        } else if (value == 'Delete') {
                                          _deleteEvent(event.id);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                            value: 'Edit', child: Text('Edit')),
                                        const PopupMenuItem(
                                            value: 'Delete',
                                            child: Text('Delete')),
                                      ],
                                    )
                                  : ElevatedButton(
                                      onPressed: () =>
                                          _toggleJoinEvent(event.id),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isJoined
                                            ? Colors.green
                                            : Colors.purple,
                                      ),
                                      child: Text(
                                        isJoined ? 'Joined' : 'Join',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: ElevatedButton(
            onPressed: () => _showEventDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'Create new event',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class EventDialog extends StatefulWidget {
  final String? eventId;
  final Map<String, dynamic>? eventData;

  const EventDialog({super.key, this.eventId, this.eventData});

  @override
  EventDialogState createState() => EventDialogState();
}

class EventDialogState extends State<EventDialog> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _place = '';
  String _description = '';
  DateTime? _startAt;
  DateTime? _endsAt;

  @override
  void initState() {
    super.initState();
    if (widget.eventData != null) {
      _name = widget.eventData!['name'];
      _place = widget.eventData!['place'];
      _description = widget.eventData!['description'];
      _startAt = widget.eventData!['startAt']?.toDate();
      _endsAt = widget.eventData!['endsAt']?.toDate();
    }
  }

  Future<void> _selectDateTime(BuildContext context, bool isStart) async {
    DateTime initialDate = isStart
        ? (_startAt ?? DateTime.now())
        : (_endsAt ?? _startAt ?? DateTime.now());
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (pickedTime != null) {
        setState(() {
          DateTime selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );

          if (isStart) {
            _startAt = selectedDateTime;
            _endsAt = null; // Reset end time if start time changes
          } else {
            if (_startAt != null && selectedDateTime.isAfter(_startAt!)) {
              _endsAt = selectedDateTime;
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('End time must be after start time.')),
              );
            }
          }
        });
      }
    }
  }

  Future<void> _saveEvent() async {
    if (_formKey.currentState!.validate() &&
        _startAt != null &&
        _endsAt != null) {
      _formKey.currentState!.save();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final eventData = {
        'name': _name,
        'place': _place,
        'description': _description,
        'startAt': Timestamp.fromDate(_startAt!),
        'endsAt': Timestamp.fromDate(_endsAt!),
        'creatorUid': user.uid,
        'creatorName': user.displayName ?? 'Anonymous',
        'joinedUsers': [],
        'createdAt':
            widget.eventId == null ? FieldValue.serverTimestamp() : null,
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
                initialValue: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a description' : null,
                onSaved: (value) => _description = value!,
              ),
              const SizedBox(height: 10),
              ListTile(
                title: Text(_startAt == null
                    ? 'Select Start Time'
                    : 'Start: ${DateFormat('yyyy-MM-dd HH:mm').format(_startAt!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDateTime(context, true),
              ),
              ListTile(
                title: Text(_endsAt == null
                    ? 'Select End Time'
                    : 'End: ${DateFormat('yyyy-MM-dd HH:mm').format(_endsAt!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDateTime(context, false),
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
        TextButton(
          onPressed: _saveEvent,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
