import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hoppy_club/shared/widgets/bottom.navigation.dart';

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
        data['id'] = doc.id;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${userProfile['firstName'] ?? 'User'} removed from favorites!')),
        );
      } else {
        await favoriteRef.set(userProfile);
        setState(() {
          favoriteIds.add(profileId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${userProfile['firstName'] ?? 'User'} added to favorites!')),
        );
      }
    } catch (e) {
      debugPrint('Failed to toggle favorite: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userProfiles.isEmpty
              ? const Center(child: Text('No profiles available.'))
              : PageView.builder(
                  itemCount: userProfiles.length,
                  itemBuilder: (context, index) {
                    final userData = userProfiles[index];
                    return SingleChildScrollView(
                      child: buildProfileCard(userData),
                    );
                  },
                ),
      bottomNavigationBar: const BottomNavBar(selectedIndex: 2),
    );
  }

  Widget buildProfileCard(Map<String, dynamic> userData) {
    final bool isFavorite = favoriteIds.contains(userData['id']);
    final String firstName = userData['firstName'] ?? 'Unknown';
    final String lastName = userData['lastName'] ?? '';
    final String fullName = '$firstName $lastName'.trim();
    final String age = userData['age']?.toString() ?? 'Unknown';
    final bool isOnline = userData['isOnline'] ?? false;
    final String profileImage =
        userData['profileImage'] ?? 'assets/default_profile.png';
    final String location =
        '${userData['city'] ?? ''}, ${userData['state'] ?? ''}, ${userData['country'] ?? ''}'
            .trim();
    final String about = userData['about'] ?? 'No details available.';
    final String hobbies = userData['hobbies'] is List
        ? (userData['hobbies'] as List).join(', ')
        : (userData['hobbies'] ?? 'Not specified');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 40), // Push image down
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    profileImage,
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.55,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: MediaQuery.of(context).size.height * 0.55,
                        color: Colors.grey[300],
                        child: const Icon(Icons.person, size: 100),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 55,
                right: 15,
                child: GestureDetector(
                  onTap: () => toggleFavorite(userData),
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.8),
                    radius: 25,
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.black,
                      size: 30,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 6,
                        backgroundColor: isOnline ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$fullName, $age',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 5,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📍 $location',
                    style: const TextStyle(
                        fontSize: 18,
                        color: const Color.fromARGB(255, 186, 8, 222))),
                const SizedBox(height: 10),
                Text('⭐ Hobbies: $hobbies',
                    style: TextStyle(
                        fontSize: 16,
                        color: const Color.fromARGB(255, 186, 8, 222))),
                const SizedBox(height: 20),
                const Text('About Me',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(about, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
