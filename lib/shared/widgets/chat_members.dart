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
      appBar: AppBar(title: const Text("Messenger")),
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

              // Ensure there are at least two participants
              if (participants.length < 2) return const SizedBox.shrink();

              // Find the other participant (excluding the current user)
              String receiverId = participants.firstWhere(
                (id) => id != widget.user.uid,
                orElse: () => "",
              );

              // Skip if no valid receiver is found
              if (receiverId.isEmpty) return const SizedBox.shrink();

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(receiverId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return const SizedBox.shrink(); // Hide invalid users
                  }

                  var receiverData =
                      userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                  //FIXME Fix the user name fetching
                  String receiverName = receiverData['name'] ?? "Unknown User";
                  String receiverProfileUrl = receiverData['profileUrl'] ?? "";

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
                      if (messageSnapshot.hasData &&
                          messageSnapshot.data!.docs.isNotEmpty) {
                        var lastMsgData = messageSnapshot.data!.docs.first;
                        lastMessage = lastMsgData['text'] ?? "No messages yet";
                      }

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: receiverProfileUrl.isNotEmpty
                              ? NetworkImage(receiverProfileUrl)
                              : null,
                          child: receiverProfileUrl.isEmpty
                              ? Icon(Icons.person)
                              : null,
                        ),
                        title: Text(receiverName),
                        subtitle: Text("Last Message: $lastMessage"),
                        onTap: () {
                          Navigator.push(
                            context,
                            //FIXME Handover chat massages
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
