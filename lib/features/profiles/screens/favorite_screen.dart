// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hoppy_club/features/home/screens/detailed_profile_page.dart';
import 'package:hoppy_club/shared/widgets/bottom.navigation.dart';
import 'package:hoppy_club/shared/widgets/private_chat_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Map<String, dynamic>> favoriteProfiles = [];
  bool isLoading = true; // Track loading state

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    fetchFavorites(); // Fetch data after UI loads
  }

  Future<void> fetchFavorites() async {
    final String userId = _auth.currentUser?.uid ?? '';
    if (userId.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    final querySnapshot = await FirebaseFirestore.instance
        .collection('favorites')
        .doc(userId)
        .collection('userFavorites')
        .get();

    if (querySnapshot.docs.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    List<String> favoriteUserIds =
        querySnapshot.docs.map((doc) => doc.id).toList();

    // Fetch all user profiles in one query
    final userSnapshots = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: favoriteUserIds)
        .get();

    List<Map<String, dynamic>> loadedProfiles = userSnapshots.docs.map((doc) {
      final userData = doc.data();
      userData['docId'] = doc.id;
      return userData;
    }).toList();

    setState(() {
      favoriteProfiles = loadedProfiles;
      isLoading = false;
    });
  }

  Future<void> removeFromFavorites(String docId, int index) async {
    final String userId = _auth.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('favorites')
        .doc(userId)
        .collection('userFavorites')
        .doc(docId)
        .delete();

    setState(() {
      favoriteProfiles.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Removed from favorites')),
    );
  }

  String createChatId(String senderId, String receiverId) {
    return senderId.hashCode <= receiverId.hashCode
        ? '${senderId}_$receiverId'
        : '${receiverId}_$senderId';
  }

  void startPrivateChat(String userId, String userName, String profileImage) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrivateChatScreen(
          receiverId: userId,
          receiverName: userName,
          receiverProfileUrl: profileImage,
          chatId: createChatId(_auth.currentUser!.uid, userId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double scaleFactor = screenWidth / 375;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Padding(
          padding: EdgeInsets.all(8.0 * scaleFactor),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: 4 / 6,
            ),
            itemCount: favoriteProfiles.isNotEmpty
                ? favoriteProfiles.length
                : (isLoading ? 6 : 1), // Show placeholders while loading
            itemBuilder: (context, index) {
              if (isLoading) {
                return _buildLoadingPlaceholder(); // Show shimmer effect
              }

              if (favoriteProfiles.isEmpty) {
                return const Center(child: Text('No favorite profiles yet.'));
              }

              final userData = favoriteProfiles[index];
              return _buildProfileCard(userData, scaleFactor, index);
            },
          ),
        ),
        bottomNavigationBar: const BottomNavBar(selectedIndex: 1),
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16.0),
      ),
    );
  }

  Widget _buildProfileCard(
      Map<String, dynamic> userData, double scaleFactor, int index) {
    final profileImage = userData['profileImage'] ?? '';
    final name = userData['firstName'] ?? 'Unknown';
    final age = userData['age']?.toString() ?? 'N/A';
    final country = userData['country'] ?? 'Unknown';
    final city = userData['city'] ?? 'Unknown';
    final userId = userData['docId'];
    final bool isOnline = userData['isOnline'] ?? false;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailedProfilePage(userId: userId),
          ),
        );
      },
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16.0 * scaleFactor),
            child: profileImage.isNotEmpty
                ? Image.network(
                    profileImage,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    'assets/profiles/profile.jpg',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
          ),
          Positioned(
            top: 10.0,
            right: 10,
            child: GestureDetector(
              onTap: () => startPrivateChat(userId, name, profileImage),
              child: const Icon(
                Icons.message,
                color: Colors.green,
                size: 30,
              ),
            ),
          ),
          Positioned(
            top: 0.0,
            left: 0.0,
            child: IconButton(
              onPressed: () async {
                await removeFromFavorites(userId, index);
              },
              icon: Icon(
                Icons.favorite,
                color: Colors.red,
                size: 30 * scaleFactor,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(8.0 * scaleFactor),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16.0 * scaleFactor),
                ),
              ),
              child: Column(
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Container(
                            width: 15 * scaleFactor,
                            height: 15 * scaleFactor,
                            margin: EdgeInsets.only(right: 4 * scaleFactor),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isOnline ? Colors.green : Colors.grey,
                            ),
                          ),
                        ),
                        TextSpan(
                          text: '$name, $age',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0 * scaleFactor,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4 * scaleFactor),
                  Text(
                    '$city, $country',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.0 * scaleFactor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
