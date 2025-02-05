// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hoppy_club/shared/widgets/private_chat%20.dart';

class DetailedProfilePage extends StatefulWidget {
  final String userId;

  const DetailedProfilePage({super.key, required this.userId});

  @override
  _DetailedProfilePageState createState() => _DetailedProfilePageState();
}

class _DetailedProfilePageState extends State<DetailedProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    checkIfFavorite();
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

  Future<void> checkIfFavorite() async {
    if (currentUserId.isEmpty) return;

    final favoriteRef = _firestore
        .collection('favorites')
        .doc(currentUserId)
        .collection('userFavorites')
        .doc(widget.userId);

    final doc = await favoriteRef.get();
    setState(() {
      isFavorite = doc.exists;
    });
  }

  Future<void> toggleFavorite() async {
    if (currentUserId.isEmpty || userData == null) return;

    final favoriteRef = _firestore
        .collection('favorites')
        .doc(currentUserId)
        .collection('userFavorites')
        .doc(widget.userId);

    try {
      if (isFavorite) {
        await favoriteRef.delete();
        setState(() {
          isFavorite = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${userData?['firstName'] ?? 'User'} removed from favorites!'),
          ),
        );
      } else {
        await favoriteRef.set(userData!);
        setState(() {
          isFavorite = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${userData?['firstName'] ?? 'User'} added to favorites!'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to toggle favorite: $e');
    }
  }

  void startPrivateChat() {
    if (userData == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrivateChatScreen(
          receiverId: widget.userId,
          receiverName: userData?['firstName'] ?? 'Unknown',
        ),
      ),
    );
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
                    child: Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.95,
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.amber, width: 8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 15,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Profile Image with Favorite & Message Icons
                            Stack(
                              children: [
                                Container(
                                  width: double.infinity,
                                  height:
                                      MediaQuery.of(context).size.height * 0.4,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    image: DecorationImage(
                                      fit: BoxFit.cover,
                                      image: userData!['profileImage'] !=
                                                  null &&
                                              userData!['profileImage']
                                                  .isNotEmpty
                                          ? NetworkImage(
                                              userData!['profileImage'])
                                          : const AssetImage(
                                                  'assets/profiles/profile.jpg')
                                              as ImageProvider,
                                    ),
                                  ),
                                  child: userData!['profileImage'] == null ||
                                          userData!['profileImage'].isEmpty
                                      ? Center(
                                          child: SizedBox(
                                            width: double.infinity,
                                            height: double.infinity,
                                            child: Image.asset(
                                              'assets/profiles/profile.jpg',
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                                // Favorite Icon
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: GestureDetector(
                                    onTap: toggleFavorite,
                                    child: CircleAvatar(
                                      backgroundColor:
                                          Colors.white.withOpacity(0.8),
                                      radius: 25,
                                      child: Icon(
                                        isFavorite
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: isFavorite
                                            ? Colors.red
                                            : Colors.black,
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                ),
                                // Message Icon
                                Positioned(
                                  top: 10,
                                  right: 60,
                                  child: GestureDetector(
                                    onTap: startPrivateChat,
                                    child: CircleAvatar(
                                      backgroundColor:
                                          Colors.white.withOpacity(0.8),
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
                            const SizedBox(height: 8),

                            Container(
                              padding: const EdgeInsets.all(15),
                              margin: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 7,
                                        backgroundColor:
                                            (userData?['isOnline'] ?? false)
                                                ? Colors.green
                                                : Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '${userData?['firstName'] ?? 'Not provided'} ${userData?['lastName'] ?? ''}, ${userData?['age'] ?? 'N/A'}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
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
                                              color: Colors.grey[700])),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on,
                                          color: Colors.purple),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${userData?['city'] ?? 'City'}\n${userData?['state'] ?? 'State'}\n${userData?['country'] ?? 'Country'}',
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey[700]),
                                          maxLines: 3,
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 12),
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
                                              color: Colors.grey[700]),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'About Me',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                      userData?['about'] ??
                                          'No details provided.',
                                      style: const TextStyle(fontSize: 16)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}
