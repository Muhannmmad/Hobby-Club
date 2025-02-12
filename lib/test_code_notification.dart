import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {
  await Firebase.initializeApp();
  await migrateFavorites();
}

/// ✅ **Fix the Firestore Favorites Structure**
Future<void> migrateFavorites() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  try {
    print("🚀 Starting Favorites Migration...");

    // ✅ Fetch all favorites
    final favoritesSnapshot = await firestore.collection('favorites').get();

    for (var doc in favoritesSnapshot.docs) {
      String favoritingUserId = doc.id;

      // ✅ Get the user's `userFavorites` subcollection (old structure)
      final userFavoritesSnapshot = await firestore
          .collection('favorites')
          .doc(favoritingUserId)
          .collection('userFavorites')
          .get();

      List<String> favoritesList = [];
      List<String> favoritedByList = [];

      for (var favDoc in userFavoritesSnapshot.docs) {
        String favoritedUserId = favDoc.id; // The user they favorited
        favoritesList.add(favoritedUserId);

        // ✅ Also update the reverse relationship
        favoritedByList.add(favoritingUserId);

        // ✅ Remove old subcollection entry (cleanup)
        await favDoc.reference.delete();
      }

      // ✅ Update the new structure
      await firestore.collection('favorites').doc(favoritingUserId).set({
        "favorites": favoritesList, // List of users they favorited
      }, SetOptions(merge: true));

      // ✅ Also update each user's `favoritedBy`
      for (String favoritedUserId in favoritesList) {
        await firestore.collection('favorites').doc(favoritedUserId).set({
          "favoritedBy": FieldValue.arrayUnion([favoritingUserId]),
        }, SetOptions(merge: true));
      }
    }

    print("✅ Migration Complete!");
  } catch (e) {
    print("❌ Error migrating favorites: $e");
  }
}
