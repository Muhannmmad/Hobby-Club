import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hoppy_club/features/home/screens/detailed_profile_page.dart';
import 'package:hoppy_club/features/home/screens/favorite_icon.dart';
import 'package:hoppy_club/features/profiles/screens/favorite_screen.dart';
import 'package:hoppy_club/shared/widgets/bottom.navigation.dart';
import 'package:hoppy_club/features/chat/private_chat_screen.dart';

class FavoritedMeScreen extends StatefulWidget {
  const FavoritedMeScreen({super.key});

  @override
  State<FavoritedMeScreen> createState() => _FavoritedMeScreenState();
}

class _FavoritedMeScreenState extends State<FavoritedMeScreen> {
  List<Map<String, dynamic>> favoriteProfiles = [];
  bool isLoading = true; // Track loading state
  bool isFavoritedMe = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    fetchFavoritedMe(); // Fetch data after UI loads
  }

  void _toggleScreen(bool value) {
    if (!value) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FavoritesScreen()),
      );
    }
  }

  Future<void> fetchFavoritedMe() async {
    final String userId = _auth.currentUser?.uid ?? '';
    if (userId.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    // 🔹 Fetch "favoritedMe" list (users who favorited the current user)
    final docSnapshot = await FirebaseFirestore.instance
        .collection('favorites')
        .doc(userId)
        .get();

    if (!docSnapshot.exists ||
        !docSnapshot.data()!.containsKey("favoritedMe")) {
      setState(() => isLoading = false);
      return;
    }

    List<String> favoritedMeUserIds =
        List<String>.from(docSnapshot["favoritedMe"]);

    if (favoritedMeUserIds.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    // 🔹 Fetch user profiles in one query
    final userSnapshots = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: favoritedMeUserIds)
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

  void startPrivateChat(String userId, String userName, String profileImage,
      String receiverOnesignalId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrivateChatScreen(
          receiverId: userId,
          receiverName: userName,
          receiverOnesignalId: receiverOnesignalId,
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
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 2), // Padding inside the box
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              // Rounded edges
              border: Border.all(color: Colors.purple, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min, // Wraps around content
              children: [
                const Text(
                  "I added",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: isFavoritedMe,
                  onChanged: (value) {
                    setState(() => isFavoritedMe = value);
                    _toggleScreen(value);
                  },
                ),
                const Text(
                  "Added me",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          centerTitle: true,
        ),
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
    final receiverOnesignalId = userData["onesignalID"] ?? "";
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
          // 🔹 Favorite Icon Positioned
          Positioned(
            top: 10.0,
            left: 10.0,
            child: FavoriteIcon(profileId: userId),
          ),
          Positioned(
            top: 10.0,
            right: 10,
            child: GestureDetector(
              onTap: () => startPrivateChat(
                  userId, name, profileImage, receiverOnesignalId),
              child: const Icon(
                Icons.message,
                color: Colors.green,
                size: 50,
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
