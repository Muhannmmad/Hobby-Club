import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
    {
      'id': 'local_3',
      'name': 'Julia Schmidt',
      'age': 28,
      'town': 'Hamburg',
      'about':
          'Travel lover and foodie. I enjoy exploring new cities and cultures.',
      'profileImage': 'assets/profiles/5.png',
      'hobbies': ['Traveling', 'Food', 'Photography'],
      'isOnline': true,
    },
    {
      'id': 'local_4',
      'name': 'Lukas Weber',
      'age': 30,
      'town': 'Munich',
      'about': 'Sports enthusiast, love football and outdoor activities.',
      'profileImage': 'assets/profiles/6.png',
      'hobbies': ['Football', 'Hiking', 'Fitness'],
      'isOnline': false,
    },
    {
      'id': 'local_5',
      'name': 'Anna Klein',
      'age': 22,
      'town': 'Stuttgart',
      'about':
          'Passionate about photography and art. Looking to meet creatives!',
      'profileImage': 'assets/profiles/1.png',
      'hobbies': ['Photography', 'Art', 'Design'],
      'isOnline': false,
    },
    {
      'id': 'local_6',
      'name': 'Leon Fischer',
      'age': 27,
      'town': 'Cologne',
      'about': 'Avid reader and writer. I enjoy discussing books and ideas.',
      'profileImage': 'assets/profiles/3.png',
      'hobbies': ['Reading', 'Writing', 'Philosophy'],
      'isOnline': false,
    },
    {
      'id': 'local_7',
      'name': 'Sophie Wagner',
      'age': 24,
      'town': 'Düsseldorf',
      'about': 'Love baking, hiking, and all things nature. Let’s explore!',
      'profileImage': 'assets/profiles/2.png',
      'hobbies': ['Baking', 'Hiking', 'Nature'],
      'isOnline': true,
    },
    {
      'id': 'local_8',
      'name': 'Hanna Becker',
      'age': 33,
      'town': 'Leipzig',
      'about': 'Music producer and cat lover. Always up for a jam session.',
      'profileImage': 'assets/profiles/4.png',
      'hobbies': ['Music', 'Cats', 'Producing'],
      'isOnline': false,
    },
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
                    return buildProfileCard(userData);
                  },
                ),
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
