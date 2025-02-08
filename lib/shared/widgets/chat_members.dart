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
                      bool isRead = false;
                      String lastMessageId = "";
                      String senderId = "";

                      if (messageSnapshot.hasData &&
                          messageSnapshot.data!.docs.isNotEmpty) {
                        var lastMsgData = messageSnapshot.data!.docs.first;
                        lastMessage = lastMsgData['text'] ?? "No messages yet";
                        senderId = lastMsgData['senderId'] ?? "";

                        // ✅ Check if message has been read
                        if (lastMsgData.data() != null &&
                            (lastMsgData.data() as Map<String, dynamic>)
                                .containsKey('isRead')) {
                          isRead = lastMsgData['isRead'] as bool;
                        } else {
                          isRead = false;
                        }

                        lastMessageId = lastMsgData.id;
                      }

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 30,
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
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                // Dynamically adjust the font size based on screen width
                                double fontSize =
                                    constraints.maxWidth < 300 ? 14 : 16;

                                return Text(
                                  lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: (!isRead &&
                                            senderId != widget.user.uid)
                                        ? Colors.red
                                        : Colors
                                            .black, // Red for unread messages
                                    fontWeight:
                                        (!isRead && senderId != widget.user.uid)
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    fontSize: fontSize, // Adjusted font size
                                  ),
                                );
                              },
                            ),
                            if (senderId == widget.user.uid && isRead)
                              const Text(
                                "Seen",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        onTap: () {
                          // Mark message as read if it's the receiver and not read yet
                          if (!isRead &&
                              lastMessageId.isNotEmpty &&
                              senderId != widget.user.uid) {
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
                                chatId: chat.id,
                              ),
                            ),
                          );
                        },
                        onLongPress: () {
                          _showDeleteConfirmation(context, chat.id);
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

  // ✅ Show confirmation dialog before deleting chat
  void _showDeleteConfirmation(BuildContext context, String chatId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Delete Chat"),
          content: const Text("Are you sure you want to delete this chat?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Close dialog
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                await _deleteChat(chatId);
                Navigator.pop(dialogContext); // Close dialog after deleting
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // ✅ Delete chat from Firestore
  Future<void> _deleteChat(String chatId) async {
    try {
      await _firestore.collection('private_chats').doc(chatId).delete();
    } catch (e) {
      print("Error deleting chat: $e");
    }
  }
}
