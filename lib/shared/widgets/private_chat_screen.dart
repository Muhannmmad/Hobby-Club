import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hoppy_club/features/home/screens/detailed_profile_page.dart';

import 'package:intl/intl.dart';

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
  bool _isSending = false;
  String? fcmToken;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    requestNotificationPermissions();
    setupFirebaseMessaging(); // ✅ Now this method exists
    initializeLocalNotifications(); // ✅ Now this method exists
  }

  void setupFirebaseMessaging() {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    messaging.getToken().then((token) {
      print("FCM Token: $token");
      // Store this token in Firestore under the user's document for push notifications
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 New foreground message: ${message.notification?.title}");
      showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("📲 Notification tapped!");
    });
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(); // ✅ Correct iOS settings

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
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

  Future<void> initNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permission
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print("❌ Notifications Denied");
      return;
    }

    // Wait for APNS token
    String? apnsToken = await messaging.getAPNSToken();
    if (apnsToken == null) {
      print("⚠️ APNS token not available yet. Retrying...");
      await Future.delayed(Duration(seconds: 5));
      apnsToken = await messaging.getAPNSToken();
    }

    if (apnsToken == null) {
      print("❌ APNS token still not set. Notifications might not work on iOS.");
    } else {
      print("✅ APNS Token: $apnsToken");
    }

    // Get FCM Token
    String? token = await messaging.getToken();
    print("🔑 FCM Token: $token");

    setState(() {
      fcmToken = token;
    });

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 Foreground Message: ${message.notification?.title}");
      showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("📲 Notification Clicked! Opened App.");
    });
  }

  void showLocalNotification(RemoteMessage message) async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title ?? "New Message",
      message.notification?.body ?? "You have a new message",
      notificationDetails,
    );
  }

  Future<void> sendMessage(String chatId, String senderId, String text) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    DocumentReference messageRef = firestore
        .collection('private_chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    DateTime now = DateTime.now();

    await messageRef.set({
      'senderId': senderId,
      'text': text,
      'timestamp': now,
      'isRead': false,
    });

    // ✅ Update lastMessageTimestamp in chat document
    await firestore.collection('private_chats').doc(chatId).update({
      'lastMessageTimestamp': now,
    });

    // 🔥 Send push notification to receiver
    sendPushNotification(widget.receiverId, text);
  }

  Future<void> sendPushNotification(String receiverId, String message) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(receiverId).get();

    if (!userDoc.exists || userDoc['fcmToken'] == null) return;

    String fcmToken = userDoc['fcmToken'];

    await FirebaseMessaging.instance.sendMessage(
      to: fcmToken,
      data: {
        'title':
            'New Message from ${_auth.currentUser?.displayName ?? "Someone"}',
        'body': message,
      },
    );
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    setState(() {
      _isSending = true; // Disable button
    });

    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception("User not found"); // Stop execution
      }

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      String firstName = userDoc['firstName'] ?? 'Unknown';
      String lastName = userDoc['lastName'] ?? '';

      final String chatId = widget.chatId;
      String messageText = _messageController.text;

      _messageController.clear(); // Clear input field immediately

      await _firestore
          .collection('private_chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'text': messageText,
        'senderId': user.uid,
        'senderName': '$firstName $lastName',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('private_chats').doc(chatId).set({
        'participants': [user.uid, widget.receiverId],
        'lastMessage': messageText,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _scrollToBottom();
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _deleteMessage(
      BuildContext context, String messageId, String chatId, String senderId) {
    User? user = _auth.currentUser;
    if (user == null || user.uid != senderId) return;

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Delete Message"),
          content: const Text("Are you sure you want to delete this message?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Close the dialog
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(
                    dialogContext); // Close the dialog before deleting
                await _firestore
                    .collection('private_chats')
                    .doc(chatId)
                    .collection('messages')
                    .doc(messageId)
                    .delete();
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void requestNotificationPermissions() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("User granted permission for notifications");
    } else {
      print("User denied notification permission");
    }
  }

  @override
  Widget build(BuildContext context) {
    final String chatId = widget.chatId;

    return Scaffold(
      backgroundColor: const Color.fromARGB(252, 0, 3, 0),
      appBar: AppBar(
        toolbarHeight: 50.0,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(252, 0, 3, 0),
        title: InkWell(
          onTap: () {
            // Navigate to DetailedProfileScreen when the AppBar is tapped
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    DetailedProfilePage(userId: widget.receiverId),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: const Color.fromARGB(255, 181, 237, 186),
                backgroundImage: widget.receiverProfileUrl.isNotEmpty
                    ? (Uri.tryParse(widget.receiverProfileUrl)
                                ?.hasAbsolutePath ==
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
                    color: Colors.white),
              ),
            ],
          ),
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
                                  color: Color.fromARGB(146, 255, 255, 255)),
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
                                      ? const Color.fromARGB(255, 2, 34, 8)
                                      : const Color.fromARGB(230, 27, 26, 26),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['text'],
                                      style: const TextStyle(
                                          fontSize: 18, color: Colors.white),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          time,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Color.fromARGB(
                                                  146, 255, 255, 255)),
                                        ),
                                        if (isMine)
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () => _deleteMessage(
                                              context, // Pass context for the confirmation dialog
                                              snapshot.data!.docs[index].id,
                                              chatId,
                                              data['senderId'],
                                            ),
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
                      child: Icon(Icons.send,
                          color: _isSending ? Colors.grey : Colors.white),
                    ),
                    onPressed: _isSending
                        ? null
                        : _sendMessage, // Disable when sending
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
