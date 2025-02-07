import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PrivateChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String receiverProfileUrl;
  final String chatId;

  const PrivateChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.receiverProfileUrl,
    required this.chatId,
  });

  @override
  PrivateChatScreenState createState() => PrivateChatScreenState();
}

class PrivateChatScreenState extends State<PrivateChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
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

    final String chatId = widget.chatId;

    await _firestore
        .collection('private_chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'text': _messageController.text,
      'senderId': user.uid,
      'senderName': '$firstName ',
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('private_chats').doc(chatId).set({
      'participants': [
        user.uid,
        widget.receiverId
      ], // Fix spelling & use correct IDs
      'lastMessage': _messageController.text,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)); // Ensures data is not overwritten

    _messageController.clear();
    _scrollToBottom();

    // Fetch receiver FCM token
    DocumentSnapshot receiverDoc =
        await _firestore.collection('users').doc(widget.receiverId).get();
    String? receiverToken = receiverDoc['fcmToken'];

    if (receiverToken != null) {
      String messageText =
          _messageController.text; // Store message before clearing
      _messageController.clear();
      _scrollToBottom();
      await sendPushNotification(
          receiverToken, '$firstName $lastName', messageText);
    }
  }

  Future<void> sendPushNotification(
      String token, String senderName, String message) async {
    const String serverKey =
        'YOUR_SERVER_KEY_HERE'; // Replace with your actual Firebase server key
    const String fcmUrl = 'https://fcm.googleapis.com/fcm/send';

    try {
      final response = await http.post(
        Uri.parse(fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode({
          'to': token,
          'notification': {
            'title': senderName,
            'body': message,
            'sound': 'default',
          },
          'data': {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'senderId': FirebaseAuth.instance.currentUser!.uid,
          },
        }),
      );

      print("FCM Response Code: ${response.statusCode}");
      print("FCM Response Body: ${response.body}");

      if (response.statusCode != 200) {
        print("FCM Error: ${response.body}");
      }
    } catch (e) {
      print("Error sending push notification: $e");
    }
  }

  void _deleteMessage(String messageId, String chatId, String senderId) async {
    User? user = _auth.currentUser;
    if (user == null || user.uid != senderId) return;

    await _firestore
        .collection('private_chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final String chatId = widget.chatId;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: const Color.fromARGB(255, 181, 237, 186),
              backgroundImage: widget.receiverProfileUrl.isNotEmpty
                  ? (Uri.tryParse(widget.receiverProfileUrl)?.hasAbsolutePath ==
                          true
                      ? NetworkImage(widget.receiverProfileUrl)
                      : null)
                  : null,
              child: widget.receiverProfileUrl.isEmpty ||
                      Uri.tryParse(widget.receiverProfileUrl)
                              ?.hasAbsolutePath !=
                          true
                  ? const Icon(Icons.person, size: 25, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              widget.receiverName,
              style: const TextStyle(
                fontSize: 16, // Smaller size
                fontWeight: FontWeight.bold,
                color: Colors.blue, // Blue color
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: _firestore
                    .collection('private_chats')
                    .doc(chatId)
                    .collection('messages')
                    .orderBy('timestamp', descending: false)
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No messages yet'));
                  }

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });

                  String? lastDisplayedDate;
                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> data = snapshot.data!.docs[index]
                          .data() as Map<String, dynamic>;
                      bool isMine = data['senderId'] == _auth.currentUser?.uid;
                      Timestamp? timestamp = data['timestamp'] as Timestamp?;
                      DateTime dateTime = timestamp?.toDate() ?? DateTime.now();
                      String date = DateFormat('MMM d, yyyy').format(dateTime);
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
                                fontSize: 16,
                                color: Colors.grey,
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
                          dateWidget,
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 2.0, horizontal: 4.0),
                            child: Align(
                              alignment: isMine
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.7,
                                ),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isMine
                                      ? const Color.fromARGB(255, 208, 220, 240)
                                      : const Color.fromARGB(
                                          255, 238, 215, 238),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['text'],
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          time,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600]),
                                        ),
                                        if (isMine)
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () => _deleteMessage(
                                                snapshot.data!.docs[index].id,
                                                chatId,
                                                data['senderId']),
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
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Enter message...',
                        filled: true,
                        fillColor: Colors.grey[300],
                        border: OutlineInputBorder(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(25)),
                          borderSide:
                              BorderSide(color: Colors.blue[900]!, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(25)),
                          borderSide:
                              BorderSide(color: Colors.blue[900]!, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(25)),
                          borderSide:
                              BorderSide(color: Colors.blue[900]!, width: 2),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Transform.rotate(
                      angle: -90 * (3.141592653589793 / 180),
                      child: const Icon(Icons.send, color: Colors.blue),
                    ),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
