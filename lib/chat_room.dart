import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hoppy_club/features/home/screens/detailed_profile_page.dart';
import 'package:hoppy_club/features/home/screens/home_screen.dart';
import 'package:hoppy_club/shared/widgets/bottom.navigation.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key});

  @override
  _ChatRoomScreenState createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    User? user = _auth.currentUser;
    if (user == null) return;

    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(user.uid).get();
    String firstName = userDoc['firstName'] ?? 'Unknown';
    String lastName = userDoc['lastName'] ?? '';

    await _firestore.collection('chatroom').add({
      'text': _messageController.text,
      'senderId': user.uid,
      'senderName': '$firstName $lastName',
      'timestamp': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
  }

  void _deleteMessage(String messageId, String senderId) async {
    User? user = _auth.currentUser;
    if (user == null || user.uid != senderId) return;

    await _firestore.collection('chatroom').doc(messageId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: _firestore
                    .collection('chatroom')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No messages yet'));
                  }

                  return ListView(
                    reverse: true,
                    children: snapshot.data!.docs.map((doc) {
                      Map<String, dynamic> data =
                          doc.data() as Map<String, dynamic>;
                      bool isMine = data['senderId'] == _auth.currentUser?.uid;
                      return ListTile(
                        title: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailedProfilePage(
                                    userId: data['senderId']),
                              ),
                            );
                          },
                          child: Text(
                            data['senderName'],
                            style: TextStyle(
                              color: Colors.blue[900],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        subtitle: Text(data['text']),
                        trailing: isMine
                            ? IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _deleteMessage(doc.id, data['senderId']),
                              )
                            : null,
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black87),
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Enter message...',
                        filled: true,
                        // ignore: deprecated_member_use
                        fillColor: Colors.blueGrey.withOpacity(0.3),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(25)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: const BottomNavBar(selectedIndex: 3),
      ),
    );
  }
}
