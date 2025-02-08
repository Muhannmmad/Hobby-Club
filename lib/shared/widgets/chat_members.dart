import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

          List<QueryDocumentSnapshot> chatDocs = snapshot.data!.docs;

          return FutureBuilder(
            future: _fetchSortedChats(chatDocs),
            builder: (context,
                AsyncSnapshot<List<Map<String, dynamic>>> sortedSnapshot) {
              if (!sortedSnapshot.hasData || sortedSnapshot.data!.isEmpty) {
                return const Center(child: Text("No chats available."));
              }

              List<Map<String, dynamic>> sortedChats = sortedSnapshot.data!;

              return ListView.builder(
                itemCount: sortedChats.length,
                itemBuilder: (context, index) {
                  var chatData = sortedChats[index];
                  String receiverId = chatData['receiverId'];
                  String receiverName = chatData['receiverName'];
                  String receiverProfileUrl = chatData['receiverProfileUrl'];
                  String lastMessage = chatData['lastMessage'];
                  DateTime? lastMessageTime = chatData['lastMessageTime'];
                  bool isRead = chatData['isRead'];
                  String lastMessageId = chatData['lastMessageId'];
                  String senderId = chatData['senderId'];
                  DateTime? seenTimestamp = chatData['seenTimestamp'];
                  String chatId = chatData['chatId'];

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
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: (!isRead && senderId != widget.user.uid)
                                ? Colors.red
                                : Colors.black,
                            fontWeight: (!isRead && senderId != widget.user.uid)
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                        if (lastMessageTime != null)
                          Text(
                            " ${DateFormat('MMM d, hh:mm a').format(lastMessageTime!)}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        if (senderId == widget.user.uid &&
                            isRead &&
                            seenTimestamp != null)
                          Text(
                            "Seen at ${DateFormat('MMM d, hh:mm a').format(seenTimestamp!)}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      if (!isRead &&
                          lastMessageId.isNotEmpty &&
                          senderId != widget.user.uid) {
                        _firestore
                            .collection('private_chats')
                            .doc(chatId)
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
                            chatId: chatId,
                          ),
                        ),
                      );
                    },
                    onLongPress: () {
                      _showDeleteConfirmation(context, chatId);
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
                Navigator.pop(dialogContext);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                await _deleteChat(chatId);
                Navigator.pop(dialogContext);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  /// Delete chat from Firestore
  Future<void> _deleteChat(String chatId) async {
    try {
      await _firestore.collection('private_chats').doc(chatId).delete();
    } catch (e) {
      print("Error deleting chat: $e");
    }
  }

  // ✅ Fetch chat data and sort by last message timestamp
  Future<List<Map<String, dynamic>>> _fetchSortedChats(
      List<QueryDocumentSnapshot> chatDocs) async {
    List<Map<String, dynamic>> chatList = [];

    for (var chat in chatDocs) {
      List<dynamic> participants = chat['participants'];
      String receiverId = participants.firstWhere(
        (id) => id != widget.user.uid,
        orElse: () => "",
      );

      if (receiverId.isEmpty) continue;

      DocumentSnapshot receiverSnapshot =
          await _firestore.collection('users').doc(receiverId).get();

      if (!receiverSnapshot.exists) continue;

      var receiverData = receiverSnapshot.data() as Map<String, dynamic>? ?? {};
      String firstName = receiverData['firstName'] ?? "Unknown";
      String lastName = receiverData['lastName'] ?? "";
      String receiverName = "$firstName $lastName";
      String receiverProfileUrl =
          receiverData['profileImage']?.toString() ?? "";

      QuerySnapshot messageSnapshot = await _firestore
          .collection('private_chats')
          .doc(chat.id)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      String lastMessage = "No messages yet";
      bool isRead = false;
      String lastMessageId = "";
      String senderId = "";
      DateTime? lastMessageTime;
      DateTime? seenTimestamp;

      if (messageSnapshot.docs.isNotEmpty) {
        var lastMsgData = messageSnapshot.docs.first;
        var lastMsgDataMap = lastMsgData.data() as Map<String, dynamic>;

        lastMessage = lastMsgDataMap['text'] ?? "No messages yet";
        senderId = lastMsgDataMap['senderId'] ?? "";
        lastMessageId = lastMsgData.id;
        isRead = lastMsgDataMap['isRead'] ?? false;
        lastMessageTime = (lastMsgDataMap['timestamp'] as Timestamp?)?.toDate();

        if (isRead) {
          seenTimestamp = (lastMsgDataMap['timestamp'] as Timestamp?)?.toDate();
        }
      }

      chatList.add({
        'chatId': chat.id,
        'receiverId': receiverId,
        'receiverName': receiverName,
        'receiverProfileUrl': receiverProfileUrl,
        'lastMessage': lastMessage,
        'lastMessageTime': lastMessageTime,
        'isRead': isRead,
        'lastMessageId': lastMessageId,
        'senderId': senderId,
        'seenTimestamp': seenTimestamp,
      });
    }

    // 🔥 Sort chats by last message timestamp (latest first)
    chatList.sort((a, b) {
      DateTime aTime = a['lastMessageTime'] ?? DateTime(2000);
      DateTime bTime = b['lastMessageTime'] ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });

    return chatList;
  }
}
