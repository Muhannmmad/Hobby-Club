import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
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
      backgroundColor: const Color.fromARGB(252, 0, 3, 0),
      appBar: AppBar(
        toolbarHeight: 50.0,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(252, 0, 3, 0),
        title: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/icons/messenger.png',
                  height: constraints.maxWidth < 500 ? 20 : 30,
                  width: constraints.maxWidth < 360 ? 20 : 30,
                ),
                const SizedBox(width: 8),
                const Text(
                  "Messenger",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: StreamBuilder(
        stream: _firestore
            .collection('private_chats')
            .where("participants", arrayContains: widget.user.uid)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> chatSnapshot) {
          if (chatSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (chatSnapshot.hasError) {
            return const Center(
                child: Text("An error occurred. Please try again."));
          }

          if (!chatSnapshot.hasData || chatSnapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No chats available.",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          List<QueryDocumentSnapshot> chatDocs = chatSnapshot.data!.docs;
          List<Stream<QuerySnapshot>> messageStreams = chatDocs.map((chat) {
            return _firestore
                .collection('private_chats')
                .doc(chat.id)
                .collection('messages')
                .orderBy('timestamp', descending: true)
                .limit(1)
                .snapshots();
          }).toList();

          return StreamBuilder(
            stream: CombineLatestStream.list(messageStreams),
            builder:
                (context, AsyncSnapshot<List<QuerySnapshot>> messageSnapshots) {
              if (messageSnapshots.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (messageSnapshots.hasError) {
                return const Center(
                    child: Text(
                  "Failed to load messages.",
                  style: TextStyle(color: Colors.white),
                ));
              }

              if (!messageSnapshots.hasData || messageSnapshots.data!.isEmpty) {
                return const Center(
                    child: Text(
                  "No messages found.",
                  style: TextStyle(color: Colors.white),
                ));
              }

              List<Map<String, dynamic>> chatList = [];

              for (int i = 0; i < chatDocs.length; i++) {
                var chatDoc = chatDocs[i];
                String chatId = chatDoc.id;
                var chatData = chatDoc.data() as Map<String, dynamic>;
                List<dynamic> participants = chatData['participants'] ?? [];

                String receiverId = participants.firstWhere(
                  (id) => id != widget.user.uid,
                  orElse: () => "",
                );

                if (receiverId.isEmpty) continue;

                var messageSnapshot = messageSnapshots.data![i];
                if (messageSnapshot.docs.isEmpty) continue;

                var lastMessageDoc = messageSnapshot.docs.first;
                var lastMessageData =
                    lastMessageDoc.data() as Map<String, dynamic>;

                DateTime? lastMessageTime =
                    (lastMessageData['timestamp'] as Timestamp?)?.toDate();
                bool isRead = lastMessageData['isRead'] ?? false;
                String lastMessage =
                    lastMessageData['text'] ?? "No messages yet";
                String senderId = lastMessageData['senderId'] ?? "";
                DateTime? seenTimestamp = isRead ? lastMessageTime : null;

                chatList.add({
                  "chatId": chatId,
                  "receiverId": receiverId,
                  "lastMessage": lastMessage,
                  "lastMessageTime": lastMessageTime,
                  "isRead": isRead,
                  "seenTimestamp": seenTimestamp,
                  "senderId": senderId,
                  "lastMessageDoc": lastMessageDoc,
                });
              }

              chatList.sort((a, b) => (b["lastMessageTime"] ?? DateTime(2000))
                  .compareTo(a["lastMessageTime"] ?? DateTime(2000)));

              return ListView.builder(
                itemCount: chatList.length,
                itemBuilder: (context, index) {
                  var chat = chatList[index];

                  return StreamBuilder(
                    stream: _firestore
                        .collection('users')
                        .doc(chat["receiverId"])
                        .snapshots(),
                    builder: (context,
                        AsyncSnapshot<DocumentSnapshot> userSnapshot) {
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const SizedBox(); // Or a loading indicator if preferred
                      }

                      if (userSnapshot.hasError) {
                        return const Text(
                          "Failed to load user data.",
                          style: TextStyle(color: Colors.white),
                        );
                      }

                      if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                        return const SizedBox(); // Handle no user data scenario
                      }

                      var receiverData =
                          userSnapshot.data!.data() as Map<String, dynamic>;

                      print("USER DATA: ${receiverData}");
                      String receiverName =
                          "${receiverData['firstName'] ?? 'Unknown'} ${receiverData['lastName'] ?? ''}";
                      String receiverProfileUrl =
                          receiverData['profileImage'] ?? "";

                      String receiverOnesignalId =
                          receiverData["onesignalID"] ?? "";

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: receiverProfileUrl.isNotEmpty
                              ? NetworkImage(receiverProfileUrl)
                              : null,
                          child: receiverProfileUrl.isEmpty
                              ? const Icon(Icons.person, size: 30)
                              : null,
                        ),
                        title: Text(receiverName,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chat["lastMessage"],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: (!chat["isRead"] &&
                                        chat["senderId"] != widget.user.uid)
                                    ? Colors.red
                                    : Colors.white,
                                fontWeight: (!chat["isRead"] &&
                                        chat["senderId"] != widget.user.uid)
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 18,
                              ),
                            ),
                            if (chat["lastMessageTime"] != null)
                              Text(
                                " ${DateFormat('MMM d, hh:mm a').format(chat["lastMessageTime"]!)}",
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color.fromARGB(146, 255, 255, 255)),
                              ),
                            if (chat["senderId"] == widget.user.uid &&
                                chat["isRead"] &&
                                chat["seenTimestamp"] != null)
                              Text(
                                "Seen at ${DateFormat('MMM d, hh:mm a').format(chat["seenTimestamp"]!)}",
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                        onTap: () async {
                          if (!chat["isRead"] &&
                              chat["senderId"] != widget.user.uid) {
                            await _firestore
                                .collection('private_chats')
                                .doc(chat["chatId"])
                                .collection('messages')
                                .doc(chat["lastMessageDoc"].id)
                                .update({'isRead': true});
                          }
                          setState(() {});
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PrivateChatScreen(
                                receiverId: chat["receiverId"],
                                receiverName: receiverName,
                                receiverOnesignalId: receiverOnesignalId,
                                receiverProfileUrl: receiverProfileUrl,
                                chatId: chat["chatId"],
                              ),
                            ),
                          );
                        },
                        onLongPress: () {
                          _showDeleteConfirmation(context, chat["chatId"]);
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
  } // ✅ Show confirmation dialog before deleting chat

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

  Future<void> _deleteChat(String chatId) async {
    try {
      // Reference to the chat messages subcollection
      var messagesRef = _firestore
          .collection('private_chats')
          .doc(chatId)
          .collection('messages');

      // Get all messages in the chat
      var messagesSnapshot = await messagesRef.get();

      // Delete each message in the subcollection
      for (var doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Now delete the main chat document
      await _firestore.collection('private_chats').doc(chatId).delete();

      ("Chat and messages deleted successfully.");
    } catch (e) {
      ("Error deleting chat: $e");
    }
  }
}
