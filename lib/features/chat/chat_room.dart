import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hoppy_club/features/home/screens/detailed_profile_page.dart';
import 'package:hoppy_club/features/chat/online_members.dart';
import 'package:hoppy_club/shared/widgets/bottom.navigation.dart';
import 'package:hoppy_club/features/chat/chat_members.dart';
import 'package:hoppy_club/features/chat/private_chat_screen.dart';

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
  ScrollController _scrollController = ScrollController();

  Map<String, bool> messageStatus = {};
  bool _isSending = false; // Add this at the top of your ChatRoomScreenStateƒ
  void _sendMessage() async {
    if (_isSending || _messageController.text.trim().isEmpty) return;

    User? user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      String firstName = userDoc['firstName'] ?? 'Unknown';

      await _firestore.collection('chatroom').add({
        'text': _messageController.text.trim(),
        'senderId': user.uid,
        'senderName': firstName,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _messageController.clear();

      // 🟢 Ensure scrolling happens after sending the message
      Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
    } catch (e) {
      debugPrint('Error sending message: $e');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
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

      print("ONE SINGLA ID: ${userDoc["onesignalID"]}");

      String receiverOnesignalId = userDoc["onesignalID"] ?? "";

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
                  receiverOnesignalId: receiverOnesignalId,
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
    _scrollController = ScrollController(); // Initialize it here
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: const Color.fromARGB(252, 0, 3, 0),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            toolbarHeight: 50.0,
            iconTheme: const IconThemeData(color: Colors.white),
            backgroundColor: const Color.fromARGB(252, 0, 3, 0),
            title: const Text(
              'Chat Room',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
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
                  child: Image.asset(
                    'assets/icons/messenger.png',
                    height: 50, // Adjust as needed
                    width: 50, // Adjust as needed
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                OnlineMembersRow(
                  showPrivateChatScreen: (String receiverId,
                      String receiverFullName,
                      String receiverProfileUrl,
                      String receiverOnesignalId) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PrivateChatScreen(
                          receiverId: receiverId,
                          receiverName: receiverFullName,
                          receiverOnesignalId: receiverOnesignalId,
                          receiverProfileUrl:
                              receiverProfileUrl, // Pass the profile image
                          chatId:
                              createChatId(_auth.currentUser!.uid, receiverId),
                        ),
                      ),
                    );
                  },
                ),
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

                      // 🔥 Scroll to bottom when a new message arrives
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
                          Timestamp? timestamp =
                              data['timestamp'] as Timestamp?;
                          DateTime dateTime = timestamp != null
                              ? timestamp.toDate()
                              : DateTime.now();

                          String time = DateFormat('hh:mm a').format(dateTime);
                          String messageDate =
                              DateFormat('yyyy-MM-dd').format(dateTime);

                          bool showDateHeader =
                              lastDisplayedDate != messageDate;
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
                                          MediaQuery.of(context).size.width *
                                              0.7,
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isMine
                                          ? const Color.fromARGB(255, 2, 34, 8)
                                          : const Color.fromARGB(
                                              230, 27, 26, 26),
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
                                              child: FutureBuilder<
                                                  DocumentSnapshot>(
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
                                                      radius: 20,
                                                      backgroundColor:
                                                          Colors.grey,
                                                    );
                                                  }
                                                  if (!snapshot.hasData ||
                                                      !snapshot.data!.exists) {
                                                    return const CircleAvatar(
                                                      radius: 20,
                                                      backgroundColor:
                                                          Colors.grey,
                                                      child: Icon(Icons.person,
                                                          size: 40,
                                                          color: Colors.purple),
                                                    );
                                                  }

                                                  Map<String, dynamic>
                                                      userData =
                                                      snapshot.data!.data()
                                                          as Map<String,
                                                              dynamic>;

                                                  String profileUrl = userData[
                                                          'profileImage'] ??
                                                      '';
                                                  bool isOnline =
                                                      userData['isOnline'] ??
                                                          false;

                                                  return Stack(
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 20,
                                                        backgroundImage:
                                                            profileUrl
                                                                    .isNotEmpty
                                                                ? NetworkImage(
                                                                    profileUrl)
                                                                : null,
                                                        backgroundColor:
                                                            Colors.grey[300],
                                                        child: profileUrl
                                                                .isEmpty
                                                            ? const Icon(
                                                                Icons.person,
                                                                size: 40,
                                                                color: Colors
                                                                    .purple)
                                                            : null,
                                                      ),
                                                      Positioned(
                                                        bottom: 2,
                                                        right: 2,
                                                        child: CircleAvatar(
                                                          radius: 6,
                                                          backgroundColor: Colors
                                                              .white, // Border
                                                          child: CircleAvatar(
                                                            radius: 5,
                                                            backgroundColor:
                                                                isOnline
                                                                    ? Colors
                                                                        .green
                                                                    : Colors
                                                                        .grey,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () =>
                                                    _showPrivateChatScreen(
                                                  data['senderId'],
                                                  data['senderName'],
                                                ),
                                                child: Text(
                                                  data['senderName'],
                                                  style: TextStyle(
                                                    fontSize: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width >
                                                            600
                                                        ? 16
                                                        : 14, // Adjust size for big screens
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                            ),
                                            if (isMine) ...[
                                              const Spacer(),
                                              IconButton(
                                                icon: const Icon(Icons.delete,
                                                    color: Colors.red),
                                                onPressed: () => _deleteMessage(
                                                    doc.id, data['senderId']),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          data['text'],
                                          style: const TextStyle(
                                              fontSize: 18,
                                              color: Colors.white),
                                        ),
                                        Text(
                                          time,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color.fromARGB(
                                                146, 255, 255, 255),
                                          ),
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
                            hintStyle: TextStyle(
                              fontSize: MediaQuery.of(context).size.width < 400
                                  ? 12
                                  : 14, // Adjust for small screens
                            ),
                            filled: true,
                            fillColor: Colors.grey[300],
                            contentPadding: EdgeInsets.symmetric(
                              horizontal:
                                  MediaQuery.of(context).size.width < 400
                                      ? 10
                                      : 15,
                              vertical: MediaQuery.of(context).size.width < 400
                                  ? 10
                                  : 15,
                            ),
                            border: OutlineInputBorder(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(25)),
                              borderSide: BorderSide(
                                  color: Colors.blue[900]!, width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(25)),
                              borderSide: BorderSide(
                                  color: Colors.blue[900]!, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(25)),
                              borderSide: BorderSide(
                                  color: Colors.blue[900]!, width: 2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                          width: 8), // Space between text field and button
                      IconButton(
                        iconSize: MediaQuery.of(context).size.width < 400
                            ? 20
                            : 24, // Adjust icon size
                        icon: Transform.rotate(
                          angle: -90 * (3.141592653589793 / 180),
                          child: Icon(
                            Icons.send,
                            color: _isSending ? Colors.grey : Colors.white,
                          ),
                        ),
                        onPressed: _isSending ? null : _sendMessage,
                      ),
                    ],
                  ),
                ),
                const BottomNavBar(selectedIndex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
