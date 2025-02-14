import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FavoriteIcon extends StatefulWidget {
  final String profileId;

  const FavoriteIcon({Key? key, required this.profileId}) : super(key: key);

  @override
  _FavoriteIconState createState() => _FavoriteIconState();
}

class _FavoriteIconState extends State<FavoriteIcon> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool isFavorited = false;
  String profileName = ''; // The name of the favorited user
  String currentUserName = ''; // Current user's name

  @override
  void initState() {
    super.initState();
    checkIfFavorited();
    fetchCurrentUserName();
  }

  Future<void> checkIfFavorited() async {
    if (currentUserId.isEmpty) return;

    final doc = await _firestore
        .collection('favorites')
        .doc(currentUserId)
        .collection('userFavorites')
        .doc(widget.profileId)
        .get();

    if (doc.exists) {
      setState(() {
        isFavorited = true;
        profileName = doc.data()?['firstName'] ?? 'User'; // Store profile name
      });
    } else {
      fetchUserName();
    }
  }

  Future<void> fetchUserName() async {
    final userDoc =
        await _firestore.collection('users').doc(widget.profileId).get();
    if (userDoc.exists) {
      setState(() {
        profileName = userDoc.data()?['firstName'] ?? 'User';
      });
    }
  }

  Future<void> fetchCurrentUserName() async {
    final userDoc =
        await _firestore.collection('users').doc(currentUserId).get();
    if (userDoc.exists) {
      setState(() {
        currentUserName = userDoc.data()?['firstName'] ?? 'You';
      });
    }
  }

  void showSnackBar(String message, Color color, {VoidCallback? undoAction}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        action: undoAction != null
            ? SnackBarAction(
                label: "Undo",
                textColor: Colors.white,
                onPressed: undoAction,
              )
            : null,
      ),
    );
  }

  Future<void> toggleFavorite() async {
    if (currentUserId.isEmpty) return;

    final favoriteRef = _firestore
        .collection('favorites')
        .doc(currentUserId)
        .collection('userFavorites')
        .doc(widget.profileId);

    final favoritedMeRef =
        _firestore.collection('favorites').doc(widget.profileId);

    try {
      if (isFavorited) {
        // Remove from favorites
        await favoriteRef.delete();
        await favoritedMeRef.update({
          "favoritedMe": FieldValue.arrayRemove([currentUserId])
        });

        setState(() {
          isFavorited = false;
        });

        showSnackBar(
          "You removed $profileName from favorites",
          Colors.red,
          undoAction: () {
            toggleFavorite(); // Undo action
          },
        );
      } else {
        // Add to favorites
        final doc =
            await _firestore.collection('users').doc(widget.profileId).get();
        if (doc.exists) {
          await favoriteRef.set({
            ...doc.data()!,
            "favoritedAt": FieldValue.serverTimestamp(), // Store timestamp
          });
          await favoritedMeRef.set({
            "favoritedMe": FieldValue.arrayUnion([currentUserId])
          }, SetOptions(merge: true));

          setState(() {
            isFavorited = true;
            profileName = doc.data()?['firstName'] ?? 'User';
          });

          showSnackBar("You added $profileName to favorites", Colors.green);
        }
      }
    } catch (e) {
      debugPrint('Failed to toggle favorite: $e');
    }
  }

  Future<void> sendNotification(String targetUserId, String message) async {
    final userRef = _firestore.collection('notifications').doc(targetUserId);

    await userRef.set({
      "messages": FieldValue.arrayUnion([message]),
      "timestamp": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: toggleFavorite,
      child: CircleAvatar(
        backgroundColor: Colors.white.withOpacity(0.8),
        radius: 25,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: Icon(
            isFavorited ? Icons.favorite : Icons.favorite_border,
            key: ValueKey(
                isFavorited), // Ensures animation triggers on state change
            color: isFavorited ? Colors.red : Colors.black,
            size: 30,
          ),
        ),
      ),
    );
  }
}
