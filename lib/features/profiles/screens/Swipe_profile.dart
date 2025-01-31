import 'package:cloud_firestore/cloud_firestore.dart';
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
  final String userId =
      'loggedInUserId'; // Replace with actual logged-in user ID
  Set<String> favoriteIds = {}; // Stores IDs of favorite users

  final List<Map<String, dynamic>> localUsers = [
    {
      'id': 'local_1',
      'name': 'Sarah Anderson',
      'age': 20,
      'town': 'Frankfurt',
      'about': 'I love drawing, cooking, and shopping!',
      'profileImage': 'assets/sara.png',
      'hobbies': ['Drawing', 'Cooking', 'Shopping'],
    },
    {
      'id': 'local_2',
      'name': 'Max Müller',
      'age': 25,
      'town': 'Berlin',
      'about': 'Musician and tech enthusiast.',
      'profileImage': 'assets/profiles/7.png',
      'hobbies': ['Music', 'Technology', 'Gaming'],
    },
  ];

  @override
  void initState() {
    super.initState();
    fetchUserProfiles();
    loadFavorites();
  }

  Future<void> fetchUserProfiles() async {
    try {
      final querySnapshot = await _firestore.collection('users').get();
      List<Map<String, dynamic>> firestoreUsers = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Ensure each profile has a unique ID
        return data;
      }).toList();

      setState(() {
        userProfiles = [...firestoreUsers, ...localUsers];
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
    try {
      final querySnapshot = await _firestore
          .collection('favorites')
          .doc(userId)
          .collection('userFavorites')
          .get();

      setState(() {
        favoriteIds = querySnapshot.docs
            .map((doc) => doc.id)
            .toSet(); // Store favorite IDs
      });
    } catch (e) {
      debugPrint('Failed to load favorites: $e');
    }
  }

  Future<void> toggleFavorite(Map<String, dynamic> userProfile) async {
    final String profileId = userProfile['id'];

    try {
      final favoriteRef = _firestore
          .collection('favorites')
          .doc(userId)
          .collection('userFavorites')
          .doc(profileId);

      if (favoriteIds.contains(profileId)) {
        await favoriteRef.delete();
        setState(() {
          favoriteIds.remove(profileId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${userProfile['name']} removed from favorites!')),
        );
      } else {
        await favoriteRef.set(userProfile);
        setState(() {
          favoriteIds.add(profileId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${userProfile['name']} added to favorites!')),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          const SizedBox(height: 20), // Moves image further down
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: userData['profileImage'] != null &&
                            userData['profileImage'].startsWith('http')
                        ? NetworkImage(userData['profileImage'])
                        : AssetImage(userData['profileImage'] ??
                            'assets/default_profile.png') as ImageProvider,
                  ),
                ),
              ),
              Positioned(
                top: 15,
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
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '${userData['name'] ?? 'Not provided'}, ${userData['age'] ?? 'N/A'}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            userData['town'] ?? 'Town not provided',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 10),
          Text(
            'Hobbies: ${userData['hobbies'] is List ? (userData['hobbies'] as List).join(', ') : userData['hobbies'] ?? 'Not provided'}',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          const Text(
            'About Me',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            userData['about'] ?? 'No details provided.',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
