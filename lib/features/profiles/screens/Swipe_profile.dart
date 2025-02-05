import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hoppy_club/shared/widgets/bottom.navigation.dart';
import 'package:hoppy_club/shared/widgets/private_chat%20.dart';

class SwipeableProfilesScreen extends StatefulWidget {
  const SwipeableProfilesScreen({super.key});

  @override
  SwipeableProfilesScreenState createState() => SwipeableProfilesScreenState();
}

class SwipeableProfilesScreenState extends State<SwipeableProfilesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> userProfiles = [];
  bool isLoading = true;
  Set<String> favoriteIds = {};
  String userId = '';

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    fetchUserProfiles();
    loadFavorites();
  }

  Future<void> fetchUserProfiles() async {
    try {
      final querySnapshot = await _firestore.collection('users').get();
      List<Map<String, dynamic>> firestoreUsers = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Assign Firestore document ID
        return data;
      }).toList();

      setState(() {
        userProfiles = firestoreUsers;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to fetch user profiles: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> loadFavorites() async {
    if (userId.isEmpty) return;

    try {
      final querySnapshot = await _firestore
          .collection('favorites')
          .doc(userId)
          .collection('userFavorites')
          .get();

      setState(() {
        favoriteIds = querySnapshot.docs.map((doc) => doc.id).toSet();
      });
    } catch (e) {
      debugPrint('Failed to load favorites: $e');
    }
  }

  Future<void> toggleFavorite(Map<String, dynamic> userProfile) async {
    if (userId.isEmpty) return;

    final String profileId = userProfile['id'];
    final favoriteRef = _firestore
        .collection('favorites')
        .doc(userId)
        .collection('userFavorites')
        .doc(profileId);

    try {
      if (favoriteIds.contains(profileId)) {
        await favoriteRef.delete();
        setState(() {
          favoriteIds.remove(profileId);
        });
      } else {
        await favoriteRef.set(userProfile);
        setState(() {
          favoriteIds.add(profileId);
        });
      }
    } catch (e) {
      debugPrint('Failed to toggle favorite: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : userProfiles.isEmpty
                ? const Center(child: Text('No profiles available.'))
                : PageView.builder(
                    itemCount: userProfiles.length,
                    itemBuilder: (context, index) {
                      final userData = userProfiles[index];
                      return buildProfileCard(userData, index);
                    },
                  ),
        bottomNavigationBar: const BottomNavBar(selectedIndex: 2),
      ),
    );
  }

  Widget buildProfileCard(Map<String, dynamic> userData, int index) {
    final bool isFavorite = favoriteIds.contains(userData['id']);
    final String fullName =
        "${userData['firstName'] ?? 'Unknown'} ${userData['lastName'] ?? ''}"
            .trim();
    final String age = userData['age']?.toString() ?? 'Unknown';
    final bool isOnline = userData['isOnline'] ?? false;
    final String profileImage = userData['profileImage'] ?? '';
    final String location =
        "${userData['city'] ?? ''}, ${userData['state'] ?? ''}, ${userData['country'] ?? ''}"
            .trim();
    final String about = userData['about'] ?? 'No details available.';
    final String hobbies = userData['hobbies'] is List
        ? (userData['hobbies'] as List).join(', ')
        : (userData['hobbies'] ?? 'Not specified');

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 50),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (index + 1 < userProfiles.length)
                Positioned(
                  top: 1,
                  left: 4,
                  right: -2,
                  child: Transform.translate(
                    offset: const Offset(15, 25),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        userProfiles[index + 1]['profileImage'] ?? '',
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height * 0.63,
                        fit: BoxFit.cover,
                        color: Colors.black.withOpacity(0.2),
                        colorBlendMode: BlendMode.darken,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/profiles/profile.jpg',
                            width: double.infinity,
                            height: MediaQuery.of(context).size.height * 0.63,
                            fit: BoxFit.cover,
                            color: Colors.black.withOpacity(0.2),
                            colorBlendMode: BlendMode.darken,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              Column(
                children: [
                  Expanded(
                    flex: 8,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            profileImage,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/profiles/profile.jpg',
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: GestureDetector(
                            onTap: () => toggleFavorite(userData),
                            child: CircleAvatar(
                              backgroundColor: Colors.white.withOpacity(0.8),
                              radius: 25,
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFavorite ? Colors.red : Colors.black,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 60,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PrivateChatScreen(
                                    receiverId: userData['id'],
                                    receiverName:
                                        userData['firstName'] ?? 'Unknown',
                                  ),
                                ),
                              );
                            },
                            child: CircleAvatar(
                              backgroundColor: Colors.white.withOpacity(0.8),
                              radius: 25,
                              child: const Icon(
                                Icons.message,
                                color: Colors.green,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 6,
                                backgroundColor:
                                    isOnline ? Colors.green : Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '$fullName, $age',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '📍 $location',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '⭐ Hobbies: $hobbies',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'About Me',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            about,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
