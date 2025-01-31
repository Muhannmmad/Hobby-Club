import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DetailedProfilePage extends StatefulWidget {
  final String userId;

  const DetailedProfilePage({super.key, required this.userId});

  @override
  _DetailedProfilePageState createState() => _DetailedProfilePageState();
}

class _DetailedProfilePageState extends State<DetailedProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final doc = await _firestore.collection('users').doc(widget.userId).get();
      if (doc.exists) {
        setState(() {
          userData = doc.data();
          isLoading = false;
        });
      } else {
        debugPrint('User document does not exist.');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch user data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Detailed Profile")),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : userData == null
                ? const Center(child: Text('No profile data found.'))
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // Profile Image
                        Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          height: MediaQuery.of(context).size.height * 0.4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: userData!['profileImage'] != null
                                  ? NetworkImage(userData!['profileImage'])
                                  : const AssetImage(
                                          'assets/default_profile.png')
                                      as ImageProvider,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // User Info Card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${userData?['firstName'] ?? 'Not provided'} ${userData?['lastName'] ?? ''}, ${userData?['age'] ?? 'N/A'}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.person,
                                        color: Colors.purple),
                                    const SizedBox(width: 8),
                                    Text(
                                      userData?['gender'] ??
                                          'Gender not provided',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        color: Colors.purple),
                                    const SizedBox(width: 8),
                                    Text(
                                      userData?['town'] ?? 'Town not provided',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.star,
                                        color: Colors.purple),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        userData?['hobbies'] ??
                                            'Hobbies not provided',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'About Me',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  userData?['about'] ?? 'No details provided.',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
