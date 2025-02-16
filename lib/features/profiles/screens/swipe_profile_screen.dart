import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hoppy_club/shared/widgets/bottom.navigation.dart';
import 'package:hoppy_club/features/chat/private_chat_screen.dart';

class SwipeableProfilesScreen extends StatefulWidget {
  const SwipeableProfilesScreen({super.key});

  @override
  SwipeableProfilesScreenState createState() => SwipeableProfilesScreenState();
}

final FirebaseAuth _auth = FirebaseAuth.instance;

class SwipeableProfilesScreenState extends State<SwipeableProfilesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> userProfiles = [];
  bool isLoading = true;
  Set<String> favoriteIds = {};
  String userId = '';
  String createChatId(String senderId, String receiverId) {
    return senderId.hashCode <= receiverId.hashCode
        ? '${senderId}_$receiverId'
        : '${receiverId}_$senderId';
  }

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

    final String profileId = userProfile['id']; // The user being favorited
    final favoriteRef = _firestore
        .collection('favorites')
        .doc(userId)
        .collection('userFavorites')
        .doc(profileId);

    final favoritedMeRef = _firestore.collection('favorites').doc(profileId);

    try {
      if (favoriteIds.contains(profileId)) {
        // ✅ Remove favorite
        await favoriteRef.delete();
        await favoritedMeRef.update({
          "favoritedMe": FieldValue.arrayRemove([userId])
        });

        setState(() {
          favoriteIds.remove(profileId);
        });

        // Show Snackbar for removal
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('you removed ${userProfile['firstName']} from favorites.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );

        print("❌ Removed from favorites");
      } else {
        // ✅ Add favorite
        await favoriteRef.set(userProfile);
        await favoritedMeRef.set({
          "favoritedMe": FieldValue.arrayUnion([userId])
        }, SetOptions(merge: true));

        setState(() {
          favoriteIds.add(profileId);
        });

        // Show Snackbar for addition
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('you added ${userProfile['firstName']} to favorites.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        print("✅ Added to favorites");
      }
    } catch (e) {
      debugPrint('🔥 Failed to toggle favorite: $e');
    }
  }

  void applySearchFilter(
      String name, int? minAge, int? maxAge, String country, String city) {
    setState(() {
      userProfiles = userProfiles.where((profile) {
        bool matchesName = name.isEmpty ||
            profile['firstName']
                .toString()
                .toLowerCase()
                .contains(name.toLowerCase());
        bool matchesAge = true;

        if (minAge != null || maxAge != null) {
          int age = int.tryParse(profile['age']?.toString() ?? '0') ?? 0;
          int min = minAge ?? 10;
          int max = maxAge ?? 100;
          matchesAge = age >= min && age <= max;
        }

        bool matchesCountry = country.isEmpty ||
            profile['country']
                .toString()
                .toLowerCase()
                .contains(country.toLowerCase());
        bool matchesCity = city.isEmpty ||
            profile['city']
                .toString()
                .toLowerCase()
                .contains(city.toLowerCase());

        return matchesName && matchesAge && matchesCountry && matchesCity;
      }).toList();
    });
  }

  void showSearchDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController countryController = TextEditingController();
    TextEditingController cityController = TextEditingController();
    int? selectedMinAge;
    int? selectedMaxAge;

    List<int> ageOptions = List.generate(
        91, (index) => index + 10); // Generates ages from 10 to 100

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Search Profiles'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                DropdownButtonFormField<int>(
                  value: selectedMinAge,
                  decoration: const InputDecoration(labelText: 'Min Age'),
                  onChanged: (value) {
                    setState(() {
                      selectedMinAge = value;
                    });
                  },
                  items: ageOptions.map((age) {
                    return DropdownMenuItem(
                      value: age,
                      child: Text('$age'),
                    );
                  }).toList(),
                ),
                DropdownButtonFormField<int>(
                  value: selectedMaxAge,
                  decoration: const InputDecoration(labelText: 'Max Age'),
                  onChanged: (value) {
                    setState(() {
                      selectedMaxAge = value;
                    });
                  },
                  items: ageOptions.map((age) {
                    return DropdownMenuItem(
                      value: age,
                      child: Text('$age'),
                    );
                  }).toList(),
                ),
                TextField(
                  controller: countryController,
                  decoration: const InputDecoration(labelText: 'Country'),
                ),
                TextField(
                  controller: cityController,
                  decoration: const InputDecoration(labelText: 'City'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await fetchUserProfiles(); // Reload all profiles before filtering
                applySearchFilter(
                  nameController.text.trim(),
                  selectedMinAge,
                  selectedMaxAge,
                  countryController.text.trim(),
                  cityController.text.trim(),
                );
                Navigator.pop(context);
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
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
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showSearchDialog();
          },
          backgroundColor: const Color.fromARGB(255, 84, 6, 104),
          child: const Icon(Icons.search, size: 32, color: Colors.white),
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
          height: MediaQuery.of(context).size.height * 0.95,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 50),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
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
                  left: 2,
                  right: -2,
                  child: Transform.translate(
                    offset: const Offset(15, 25),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        userProfiles[index + 1]['profileImage'] ?? '',
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height * 0.55,
                        fit: BoxFit.cover,
                        color: Colors.black.withValues(alpha: 0.2),
                        colorBlendMode: BlendMode.darken,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/profiles/profile.jpg',
                            width: double.infinity,
                            height: MediaQuery.of(context).size.height * 0.55,
                            fit: BoxFit.cover,
                            color: Colors.black.withValues(alpha: 0.2),
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
                            width: MediaQuery.of(context).size.width * 0.95,
                            height: MediaQuery.of(context).size.height * 0.65,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/profiles/profile.jpg',
                                width: MediaQuery.of(context).size.width *
                                    0.95, // 90% of screen width
                                height: MediaQuery.of(context).size.height *
                                    0.65, // 50% of screen height
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
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.8),
                              radius: 25,
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFavorite ? Colors.red : Colors.black,
                                size: 35,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 75,
                          right: 10,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PrivateChatScreen(
                                    receiverId: userData['id'],
                                    receiverName:
                                        userData['firstName'] ?? 'Unknown',
                                    receiverProfileUrl:
                                        userData['profileImage'] ?? '',
                                    receiverOnesignalId:
                                        userData["onesignalID"] ?? "",
                                    chatId: createChatId(
                                        _auth.currentUser!.uid, userData['id']),
                                  ),
                                ),
                              );
                            },
                            child: CircleAvatar(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.8),
                              radius: 25,
                              child: const Icon(
                                Icons.message,
                                color: Colors.green,
                                size: 35,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(255, 148, 82, 82)
                              .withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
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
