import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hoppy_club/features/home/screens/detailed_profile_page.dart';
import 'package:hoppy_club/shared/widgets/bottom.navigation.dart';
import 'package:hoppy_club/shared/widgets/chat_members.dart';
import 'package:hoppy_club/shared/widgets/private_chat_screen.dart';

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

  Map<String, bool> messageStatus = {};

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  String createChatId(String senderId, String receiverId) {
    return senderId.hashCode <= receiverId.hashCode
        ? '${senderId}_$receiverId'
        : '${receiverId}_$senderId';
  }

  void _showPrivateChatScreen(
      String receiverId, String receiverFullName) async {
    try {
      // Fetch receiver's details from Firestore
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(receiverId).get();

      String firstName = userDoc['firstName'] ?? 'Unknown'; // Get first name
      String profileImageUrl =
          userDoc['profileImage'] ?? ''; // Get profile image

      // Mark unread messages as read
      QuerySnapshot unreadMessages = await _firestore
          .collection('privateMessages')
          .where('receiverId', isEqualTo: _auth.currentUser?.uid)
          .where('senderId', isEqualTo: receiverId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in unreadMessages.docs) {
        await doc.reference.update({'isRead': true});
      }

      _toggleMessageStatus(receiverId);

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.8,
              width: MediaQuery.of(context).size.width * 0.8,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 219, 155, 213),
                borderRadius:
                    BorderRadius.circular(20), // Applies rounded corners
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: PrivateChatScreen(
                  receiverId: receiverId,
                  receiverName: firstName,
                  receiverProfileUrl: profileImageUrl,
                  chatId: createChatId(_auth.currentUser!.uid, receiverId),
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Error fetching receiver details: $e');
    }
  }

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

    DocumentReference newMessageRef = _firestore.collection('chatroom').doc();

    await newMessageRef.set({
      'text': _messageController.text,
      'senderId': user.uid,
      'senderName': '$firstName ',
      'timestamp': FieldValue.serverTimestamp(),
    });

    await Future.delayed(const Duration(milliseconds: 500));

    _messageController.clear();
    _scrollToBottom();
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Chat Room',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () {
                  User? currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ChatMembersScreen(user: currentUser),
                      ),
                    );
                  } else {
                    debugPrint("⚠️ No authenticated user found!");
                  }
                },
                // ignore: prefer_const_constructors
                child: Row(
                  children: const [
                    Icon(
                      Icons.message,
                      size: 40,
                      color: Color.fromARGB(255, 3, 21, 187),
                    ),
                    SizedBox(width: 4), // Add spacing between icon and text
                    Text(
                      'Messenger',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(
                            255, 3, 21, 187), // Same color as the icon
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder(
                  stream: _firestore
                      .collection('chatroom')
                      .where('timestamp',
                          isNotEqualTo: null) // Ignore null timestamps
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
                        DocumentSnapshot doc = snapshot.data!.docs[index];
                        Map<String, dynamic> data =
                            doc.data() as Map<String, dynamic>;
                        bool isMine =
                            data['senderId'] == _auth.currentUser?.uid;
                        Timestamp? timestamp = data['timestamp'] as Timestamp?;
                        DateTime dateTime = timestamp != null
                            ? timestamp.toDate()
                            : DateTime.now();

                        String time = DateFormat('hh:mm a').format(dateTime);
                        String messageDate =
                            DateFormat('yyyy-MM-dd').format(dateTime);

                        bool showDateHeader = lastDisplayedDate != messageDate;
                        if (showDateHeader) {
                          lastDisplayedDate = messageDate;
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (showDateHeader)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  DateFormat('EEEE, MMM d, yyyy')
                                      .format(dateTime),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
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
                                          Row(
                                            children: [
                                              FutureBuilder<DocumentSnapshot>(
                                                future: FirebaseFirestore
                                                    .instance
                                                    .collection('users')
                                                    .doc(data['senderId'])
                                                    .get(),
                                                builder: (context, snapshot) {
                                                  if (snapshot
                                                          .connectionState ==
                                                      ConnectionState.waiting) {
                                                    return const CircleAvatar(
                                                      radius: 12,
                                                      backgroundColor:
                                                          Colors.grey,
                                                    );
                                                  }
                                                  if (!snapshot.hasData ||
                                                      !snapshot.data!.exists) {
                                                    return const CircleAvatar(
                                                      radius: 12,
                                                      backgroundColor:
                                                          Colors.grey,
                                                      child: Icon(Icons.person,
                                                          size: 12,
                                                          color: Colors.white),
                                                    );
                                                  }
                                                  String profileUrl =
                                                      snapshot.data!.get(
                                                              'profileImage') ??
                                                          '';
                                                  return CircleAvatar(
                                                    radius: 20,
                                                    backgroundImage:
                                                        profileUrl.isNotEmpty
                                                            ? NetworkImage(
                                                                profileUrl)
                                                            : null,
                                                    backgroundColor:
                                                        Colors.grey[300],
                                                    child: profileUrl.isEmpty
                                                        ? const Icon(
                                                            Icons.person,
                                                            size: 12,
                                                            color: Colors.white)
                                                        : null,
                                                  );
                                                },
                                              ),
                                              const SizedBox(width: 4),
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
                                                child: Text(
                                                  data['senderName'],
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              GestureDetector(
                                                onTap: () =>
                                                    _showPrivateChatScreen(
                                                  data['senderId'],
                                                  data['senderName'],
                                                ),
                                                child: const Icon(
                                                  Icons.message,
                                                  color: Colors.green,
                                                  size: 40,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Text(
                                        data['text'],
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
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
              const BottomNavBar(selectedIndex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
