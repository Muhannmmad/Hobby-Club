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

  // Predefined local users
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
    // Add more predefined users here...
  ];

  @override
  void initState() {
    super.initState();
    fetchUserProfiles();
  }

  Future<void> fetchUserProfiles() async {
    try {
      final querySnapshot = await _firestore.collection('users').get();
      List<Map<String, dynamic>> firestoreUsers =
          querySnapshot.docs.map((doc) => doc.data()).toList();

      setState(() {
        userProfiles = [...firestoreUsers, ...localUsers];
        isLoading = false;
      });

      debugPrint('Total profiles loaded: ${userProfiles.length}');
    } catch (e) {
      debugPrint('Failed to fetch user profiles: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profiles'),
        centerTitle: true,
        backgroundColor: Colors.purple,
      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
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
