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

  @override
  void initState() {
    super.initState();
    checkIfFavorited();
  }

  Future<void> checkIfFavorited() async {
    if (currentUserId.isEmpty) return;

    final doc = await _firestore
        .collection('favorites')
        .doc(currentUserId)
        .collection('userFavorites')
        .doc(widget.profileId)
        .get();

    setState(() {
      isFavorited = doc.exists;
    });
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
      } else {
        // Add to favorites
        final doc =
            await _firestore.collection('users').doc(widget.profileId).get();
        if (doc.exists) {
          await favoriteRef.set(doc.data()!);
          await favoritedMeRef.set({
            "favoritedMe": FieldValue.arrayUnion([currentUserId])
          }, SetOptions(merge: true));

          setState(() {
            isFavorited = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to toggle favorite: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: toggleFavorite,
      child: CircleAvatar(
        backgroundColor: Colors.white.withOpacity(0.8),
        radius: 25,
        child: Icon(
          isFavorited ? Icons.favorite : Icons.favorite_border,
          color: isFavorited ? Colors.red : Colors.black,
          size: 30,
        ),
      ),
    );
  }
}
