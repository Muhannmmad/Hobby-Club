// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hoppy_club/features/home/screens/detailed_profile_page.dart';
import 'package:hoppy_club/shared/widgets/bottom.navigation.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<Map<String, dynamic>>> _favoritesFuture;
  List<Map<String, dynamic>> favoriteProfiles = [];

  @override
  void initState() {
    super.initState();
    _favoritesFuture = fetchFavorites();
  }

  Future<void> removeFromFavorites(String docId, int index) async {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
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

  Future<List<Map<String, dynamic>>> fetchFavorites() async {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) return [];

    final querySnapshot = await FirebaseFirestore.instance
        .collection('favorites')
        .doc(userId)
        .collection('userFavorites')
        .get();

    List<Map<String, dynamic>> favorites = [];
    for (var doc in querySnapshot.docs) {
      final favoriteData = doc.data();
      final userId = doc.id;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() ?? {};
        favoriteData.addAll(userData);
        favoriteData['docId'] = userId;
        favorites.add(favoriteData);
      }
    }
    return favorites;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double scaleFactor = screenWidth / 375;

    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Failed to load favorites.'));
          } else if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(child: Text('No favorite profiles yet.'));
          }

          favoriteProfiles = snapshot.data!;

          return Padding(
            padding: EdgeInsets.all(8.0 * scaleFactor),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: 4 / 6,
              ),
              itemCount: favoriteProfiles.length,
              itemBuilder: (context, index) {
                final userData = favoriteProfiles[index];
                final profileImage = userData['profileImage'] ?? '';
                final name = userData['firstName'] ?? 'Unknown';
                final age = userData['age']?.toString() ?? 'N/A';
                final country = userData['country'] ?? 'Unknown';
                final city = userData['city'] ?? 'Unknown';
                final userId = userData['docId'];
                final bool isOnline = userData['isOnline'];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DetailedProfilePage(userId: userId),
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
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: Icon(Icons.person,
                                        size: 120 * scaleFactor),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey[300],
                                child:
                                    Icon(Icons.person, size: 120 * scaleFactor),
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
                                        width: 10 * scaleFactor,
                                        height: 10 * scaleFactor,
                                        margin: EdgeInsets.only(
                                            right: 4 * scaleFactor),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isOnline
                                              ? Colors.green
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                    TextSpan(
                                      text: '$name, $age',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.0 * scaleFactor,
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
                      Positioned(
                        top: 0.0,
                        right: 0.0,
                        child: IconButton(
                          onPressed: () async {
                            await removeFromFavorites(userId, index);
                          },
                          icon: Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 24 * scaleFactor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: const BottomNavBar(selectedIndex: 1),
    );
  }
}
