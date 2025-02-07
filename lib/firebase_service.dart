import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseService {
  // Function to store FCM token for both sender and receiver
  Future<void> storeFCMToken(String receiverUserId) async {
    // Get FCM token for the current user (sender)
    String? senderToken = await FirebaseMessaging.instance.getToken();
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null && senderToken != null) {
      // Store the sender's FCM token
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'fcmToken': senderToken,
      });
      ("Sender FCM Token stored for user ${user.uid}: $senderToken");
    }

    // Now, store the receiver's FCM token (if available)
    String? receiverToken = await getReceiverFCMToken(receiverUserId);
    if (receiverToken == null) {
      // If the receiver's token is missing, you can get it and store it
      String? newReceiverToken = await FirebaseMessaging.instance.getToken();
      if (newReceiverToken != null) {
        // Store the receiver's FCM token
        await FirebaseFirestore.instance
            .collection('users')
            .doc(receiverUserId)
            .update({
          'fcmToken': newReceiverToken,
        });
        ("Receiver FCM Token stored for user $receiverUserId: $newReceiverToken");
      }
    }
  }

  // Get the receiver's FCM token from Firestore
  Future<String?> getReceiverFCMToken(String receiverUserId) async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(receiverUserId)
        .get();
    if (snapshot.exists && snapshot['fcmToken'] != null) {
      return snapshot['fcmToken'];
    }
    return null;
  }
}
