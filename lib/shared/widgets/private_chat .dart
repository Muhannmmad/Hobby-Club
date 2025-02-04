import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PrivateChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const PrivateChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  _PrivateChatScreenState createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
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
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
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

    String chatId = user.uid.hashCode <= widget.receiverId.hashCode
        ? '${user.uid}_${widget.receiverId}'
        : '${widget.receiverId}_${user.uid}';

    await _firestore
        .collection('private_chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'text': _messageController.text,
      'senderId': user.uid,
      'senderName': '$firstName $lastName',
      'timestamp': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
    _scrollToBottom();
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
    String chatId =
        _auth.currentUser!.uid.hashCode <= widget.receiverId.hashCode
            ? '${_auth.currentUser!.uid}_${widget.receiverId}'
            : '${widget.receiverId}_${_auth.currentUser!.uid}';

    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverName)),
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
