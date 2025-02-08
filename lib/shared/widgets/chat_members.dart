import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'private_chat_screen.dart';

class ChatMembersScreen extends StatefulWidget {
  final User user;

  const ChatMembersScreen({super.key, required this.user});

  @override
  ChatMembersScreenState createState() => ChatMembersScreenState();
}

class ChatMembersScreenState extends State<ChatMembersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var chat = snapshot.data!.docs[index];
              List<dynamic> participants = chat['participants'];

              // Find the other participant (excluding the current user)
              String receiverId = participants.firstWhere(
                (id) => id != widget.user.uid,
                orElse: () => "",
              );

              if (receiverId.isEmpty) return const SizedBox.shrink();

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(receiverId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return const SizedBox.shrink(); // Hide invalid users
                  }

                  var receiverData =
                      userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                  String firstName = receiverData['firstName'] ?? "Unknown";
                  String lastName = receiverData['lastName'] ?? "";
                  String receiverName = "$firstName $lastName";

                  String receiverProfileUrl =
                      receiverData['profileImage']?.toString() ?? "";

                  return StreamBuilder(
                    stream: _firestore
                        .collection('private_chats')
                        .doc(chat.id)
                        .collection('messages')
                        .orderBy('timestamp', descending: true)
                        .limit(1)
                        .snapshots(),
                    builder: (context,
                        AsyncSnapshot<QuerySnapshot> messageSnapshot) {
                      String lastMessage = "No messages yet";
                      bool isRead = false; // Default to false (unread)
                      String lastMessageId = "";

                      if (messageSnapshot.hasData &&
                          messageSnapshot.data!.docs.isNotEmpty) {
                        var lastMsgData = messageSnapshot.data!.docs.first;
                        lastMessage = lastMsgData['text'] ?? "No messages yet";

                        // ✅ Safely check if "isRead" exists before accessing
                        if (lastMsgData.data() != null &&
                            (lastMsgData.data() as Map<String, dynamic>)
                                .containsKey('isRead')) {
                          isRead = lastMsgData['isRead'] as bool;
                        } else {
                          isRead =
                              false; // Default to false if field is missing
                        }

                        lastMessageId = lastMsgData.id;
                      }

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 30, // Bigger Profile Image
                          backgroundColor: Colors.grey[300],
                          backgroundImage: receiverProfileUrl.isNotEmpty
                              ? NetworkImage(receiverProfileUrl)
                              : null,
                          child: receiverProfileUrl.isEmpty
                              ? const Icon(Icons.person, size: 30)
                              : null,
                        ),
                        title: Text(
                          receiverName,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isRead ? Colors.black : Colors.red,
                            fontWeight:
                                isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          // ✅ **Mark message as read when chat is opened**
                          if (!isRead && lastMessageId.isNotEmpty) {
                            _firestore
                                .collection('private_chats')
                                .doc(chat.id)
                                .collection('messages')
                                .doc(lastMessageId)
                                .update({'isRead': true});
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PrivateChatScreen(
                                receiverId: receiverId,
                                receiverName: receiverName,
                                receiverProfileUrl: receiverProfileUrl,
                                chatId: chat.id, // Pass chatId correctly
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
