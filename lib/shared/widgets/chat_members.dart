import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'private_chat_screen.dart';

class ChatMembersScreen extends StatefulWidget {
  final User user;

  const ChatMembersScreen({super.key, required this.user});

  @override
  ChatMembersScreenState createState() => ChatMembersScreenState();
}

class ChatMembersScreenState extends State<ChatMembersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _listenForNewMessages();
  }

  void _initializeNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _listenForNewMessages() {
    _firestore
        .collection('private_chats')
        .where("participants", arrayContains: widget.user.uid)
        .snapshots()
        .listen((snapshot) {
      for (var chat in snapshot.docs) {
        _firestore
            .collection('private_chats')
            .doc(chat.id)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .snapshots()
            .listen((messageSnapshot) {
          if (messageSnapshot.docs.isNotEmpty) {
            var lastMessage = messageSnapshot.docs.first;
            String senderId = lastMessage['senderId'];
            String text = lastMessage['text'] ?? "New message";

            if (senderId != widget.user.uid) {
              _firestore
                  .collection('users')
                  .doc(senderId)
                  .get()
                  .then((userDoc) {
                String senderName = userDoc.data()?['firstName'] ?? "Someone";
                _showNotification(senderName, text);
              });
            }
          }
        });
      }
    });
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'chat_channel',
      'Chat Messages',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Messenger",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue[900],
          ),
        ),
      ),
      body: StreamBuilder(
        stream: _firestore
            .collection('private_chats')
            .where("participants", arrayContains: widget.user.uid)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No chats available."));
          }

          var chats = snapshot.data!.docs;

          return FutureBuilder(
            future: Future.wait(chats.map((chat) async {
              var messageSnapshot = await _firestore
                  .collection('private_chats')
                  .doc(chat.id)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .limit(1)
                  .get();

              return {
                'chat': chat,
                'lastMessage': messageSnapshot.docs.isNotEmpty
                    ? messageSnapshot.docs.first
                    : null,
              };
            }).toList()),
            builder: (context,
                AsyncSnapshot<List<Map<String, dynamic>>> sortedSnapshot) {
              if (!sortedSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var sortedChats = sortedSnapshot.data!
                ..sort((a, b) {
                  var aTimestamp =
                      a['lastMessage']?.get('timestamp') ?? Timestamp(0, 0);
                  var bTimestamp =
                      b['lastMessage']?.get('timestamp') ?? Timestamp(0, 0);
                  return bTimestamp.compareTo(aTimestamp);
                });

              return ListView.builder(
                itemCount: sortedChats.length,
                itemBuilder: (context, index) {
                  var chat = sortedChats[index]['chat'];
                  var lastMessage = sortedChats[index]['lastMessage'];
                  List<dynamic> participants = chat['participants'];

                  String receiverId = participants.firstWhere(
                    (id) => id != widget.user.uid,
                    orElse: () => "",
                  );

                  if (receiverId.isEmpty) return const SizedBox.shrink();

                  return FutureBuilder<DocumentSnapshot>(
                    future:
                        _firestore.collection('users').doc(receiverId).get(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                        return const SizedBox.shrink();
                      }

                      var receiverData =
                          userSnapshot.data!.data() as Map<String, dynamic>? ??
                              {};
                      String receiverName =
                          "${receiverData['firstName'] ?? "Unknown"} ${receiverData['lastName'] ?? ""}";
                      String receiverProfileUrl =
                          receiverData['profileImage']?.toString() ?? "";
                      String lastMessageText =
                          lastMessage?['text'] ?? "No messages yet";

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: receiverProfileUrl.isNotEmpty
                              ? NetworkImage(receiverProfileUrl)
                              : null,
                          child: receiverProfileUrl.isEmpty
                              ? const Icon(Icons.person, size: 35)
                              : null,
                        ),
                        title: Text(receiverName,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                        subtitle: Text(lastMessageText,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PrivateChatScreen(
                                receiverId: receiverId,
                                receiverName: receiverName,
                                receiverProfileUrl: receiverProfileUrl,
                                chatId: chat.id,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
