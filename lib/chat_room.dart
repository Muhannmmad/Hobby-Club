import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hoppy_club/features/home/screens/detailed_profile_page.dart';
import 'package:hoppy_club/shared/widgets/bottom.navigation.dart';
import 'package:hoppy_club/shared/widgets/private_chat%20.dart';

import 'package:intl/intl.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key});

  @override
  ChatRoomScreenState createState() => ChatRoomScreenState();
}

class ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();

  Map<String, bool> messageStatus =
      {}; // Store toggle state for private messages

  void _toggleMessageStatus(String senderId) {
    setState(() {
      messageStatus[senderId] = !(messageStatus[senderId] ?? false);
    });
  }

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

    bool? confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      await _firestore.collection('chatroom').doc(messageId).delete();
    }
  }

  void _showPrivateChatScreen(String receiverId, String receiverName) async {
    QuerySnapshot unreadMessages = await _firestore
        .collection('privateMessages')
        .where('receiverId', isEqualTo: _auth.currentUser?.uid)
        .where('senderId', isEqualTo: receiverId)
        .where('isRead', isEqualTo: false)
        .get();

    // Mark messages as read
    for (var doc in unreadMessages.docs) {
      await doc.reference.update({'isRead': true});
    }

    // Toggle message icon color for the clicked user
    _toggleMessageStatus(receiverId);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.8,
            width: MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 219, 155, 213),
              borderRadius: BorderRadius.circular(20),
            ),
            child: PrivateChatScreen(
              receiverId: receiverId,
              receiverName: receiverName,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder(
                  stream: _firestore
                      .collection('chatroom')
                      .orderBy('timestamp', descending: false)
                      .snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No messages yet'));
                    }

                    String? lastDisplayedDate;
                    return ListView.builder(
                      controller: _scrollController, // Add ScrollController
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        DocumentSnapshot doc = snapshot.data!.docs[index];
                        Map<String, dynamic> data =
                            doc.data() as Map<String, dynamic>;
                        bool isMine =
                            data['senderId'] == _auth.currentUser?.uid;
                        Timestamp? timestamp = data['timestamp'] as Timestamp?;
                        DateTime dateTime =
                            timestamp?.toDate() ?? DateTime.now();
                        String date =
                            DateFormat('MMM d, yyyy').format(dateTime);
                        String time = DateFormat('hh:mm a').format(dateTime);

                        Widget dateWidget = const SizedBox.shrink();
                        if (lastDisplayedDate != date) {
                          lastDisplayedDate = date;
                          dateWidget = Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Center(
                              child: Text(
                                date,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color.fromARGB(255, 63, 63, 63),
                                ),
                              ),
                            ),
                          );
                        }

                        return Column(
                          crossAxisAlignment: isMine
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (index == 0 || lastDisplayedDate != date)
                              dateWidget,
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 2.0, horizontal: 8.0),
                              child: Align(
                                alignment: isMine
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.7,
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isMine
                                        ? const Color.fromARGB(
                                            255, 210, 227, 239)
                                        : const Color.fromARGB(
                                            255, 250, 227, 245),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    DetailedProfilePage(
                                                  userId: data['senderId'],
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Text(
                                                  data['senderName'],
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                GestureDetector(
                                                  onTap: () =>
                                                      _showPrivateChatScreen(
                                                    data['senderId'],
                                                    data['senderName'],
                                                  ),
                                                  child: StreamBuilder<
                                                      QuerySnapshot>(
                                                    stream: _firestore
                                                        .collection(
                                                            'privateMessages')
                                                        .where('receiverId',
                                                            isEqualTo: _auth
                                                                .currentUser
                                                                ?.uid)
                                                        .where('senderId',
                                                            isEqualTo: data[
                                                                'senderId'])
                                                        .where('isRead',
                                                            isEqualTo: false)
                                                        .snapshots(),
                                                    builder:
                                                        (context, snapshot) {
                                                      bool hasUnreadMessage =
                                                          snapshot.hasData &&
                                                              snapshot
                                                                  .data!
                                                                  .docs
                                                                  .isNotEmpty;

                                                      return Icon(
                                                        Icons.message,
                                                        color: messageStatus[data[
                                                                    'senderId']] ==
                                                                true
                                                            ? Colors.green
                                                            : (hasUnreadMessage
                                                                ? Colors.red
                                                                : Colors.green),
                                                        size: 20,
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        data['text'],
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              time,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600]),
                                            ),
                                          ),
                                          if (isMine)
                                            IconButton(
                                              icon: const Icon(Icons.delete,
                                                  color: Colors.red),
                                              onPressed: () => _deleteMessage(
                                                  doc.id, data['senderId']),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 12.0, horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Enter message...',
                          filled: true,
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
              const BottomNavBar(selectedIndex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
