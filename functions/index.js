const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendNotificationOnMessage = functions.firestore
    .document("chats/{chatId}/messages/{messageId}")
    .onCreate(async (snapshot, context) => {
        const messageData = snapshot.data();
        const receiverId = messageData.receiverId;

        // Get receiver's FCM token
        const userDoc = await admin.firestore().collection("users").doc(receiverId).get();
        if (!userDoc.exists || !userDoc.data().fcmToken) {
            console.log("No FCM token for user:", receiverId);
            return null;
        }

        const fcmToken = userDoc.data().fcmToken;

        // Notification payload
        const payload = {
            notification: {
                title: "New Message",
                body: `${messageData.message}`,
                click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            data: {
                senderId: messageData.senderId,
                chatId: context.params.chatId,
            },
        };

        // Send notification
        return admin.messaging().sendToDevice(fcmToken, payload);
    });
