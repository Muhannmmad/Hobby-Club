import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateChatButton extends StatelessWidget {
  final String receiverId; // ID of the user you want to chat with
  const CreateChatButton({super.key, required this.receiverId});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        await createPrivateChat(receiverId);
      },
      child: const Text("Start Chat"),
    );
  }

  Future<void> createPrivateChat(String receiverId) async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Generate a unique and consistent chat ID (sorted alphabetically)
    List<String> sortedUsers = [currentUserId, receiverId]..sort();
    String chatId = "${sortedUsers[0]}_${sortedUsers[1]}";

    DocumentReference chatRef =
        firestore.collection("private_chats").doc(chatId);

    // Check if chat already exists
    DocumentSnapshot chatSnapshot = await chatRef.get();
    if (!chatSnapshot.exists) {
      // Create chat document with participants array
      await chatRef.set({
        "participants": sortedUsers,
        "createdAt": FieldValue.serverTimestamp(),
      });

      // Add a welcome message (optional)
      await chatRef.collection("messages").add({
        "senderId": "system",
        "text": "Chat started!",
        "timestamp": FieldValue.serverTimestamp(),
      });

      debugPrint("Chat created successfully!");
    } else {
      debugPrint("Chat already exists.");
    }
  }
}
