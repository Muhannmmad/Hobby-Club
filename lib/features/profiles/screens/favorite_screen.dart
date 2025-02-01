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
      final data = doc.data();
      data['docId'] = doc.id;

      // Fetch user's online status
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(doc.id)
          .get();
      data['isOnline'] = userDoc.data()?['isOnline'] ?? false;

      favorites.add(data);
    }
    return favorites;
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

  @override
  Widget build(BuildContext context) {
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

          if (favoriteProfiles.isEmpty) {
            favoriteProfiles = snapshot.data!;
          }

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: 3 / 4,
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
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        elevation: 4.0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16.0),
                              ),
                              child: profileImage.isNotEmpty
                                  ? Image.network(
                                      profileImage,
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Icon(Icons.person,
                                            size: 120);
                                      },
                                    )
                                  : const Icon(Icons.person, size: 120),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        isOnline ? Colors.green : Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$name, $age',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$city, $country',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 8.0,
                        right: 8.0,
                        child: IconButton(
                          onPressed: () async {
                            await removeFromFavorites(userId, index);
                          },
                          icon: const Icon(
                            Icons.favorite,
                            color: Colors.red,
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
