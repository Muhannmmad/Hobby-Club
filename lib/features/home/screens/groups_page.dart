import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hoppy_club/features/home/screens/detailed_profile_page.dart';

class GroupPage extends StatefulWidget {
  final String groupId;

  const GroupPage({super.key, required this.groupId});

  @override
  _GroupPageState createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoading = false;
  bool isMember = false;
  List<String> memberIds = [];

  @override
  void initState() {
    super.initState();
    _setupGroupListener();
  }

  void _setupGroupListener() {
    _firestore
        .collection('groups')
        .doc(widget.groupId)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        List<dynamic> members =
            (doc.data() as Map<String, dynamic>)['members'] ?? [];
        setState(() {
          memberIds = members.cast<String>();
          isMember = memberIds.contains(_auth.currentUser?.uid);
        });
      }
    });
  }

  Future<void> _toggleMembership() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    String? userId = _auth.currentUser?.uid;
    DocumentReference groupRef =
        _firestore.collection('groups').doc(widget.groupId);

    try {
      if (isMember) {
        await groupRef.update({
          'members': FieldValue.arrayRemove([userId])
        });
      } else {
        await groupRef.update({
          'members': FieldValue.arrayUnion([userId])
        });
      }
    } catch (e) {
      print("Error toggling membership: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _navigateToDetailedProfile(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailedProfilePage(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Group Members")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: isLoading ? null : _toggleMembership,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
            ),
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    isMember ? "Leave Group" : "Join Group",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: memberIds.isEmpty
                ? const Center(child: Text("No members yet."))
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                      childAspectRatio: 1 / 1.3,
                    ),
                    itemCount: memberIds.length,
                    itemBuilder: (context, index) {
                      return FutureBuilder<DocumentSnapshot>(
                        future: _firestore
                            .collection('users')
                            .doc(memberIds[index])
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData || snapshot.data == null) {
                            return const SizedBox.shrink();
                          }

                          var userData =
                              snapshot.data!.data() as Map<String, dynamic>?;

                          if (userData == null) {
                            return const SizedBox.shrink();
                          }

                          // Fetch profile data
                          String profileImage = userData['profileImage'] ??
                              'https://via.placeholder.com/100'; // Fallback image
                          String firstName = userData['firstName'] ?? 'Unknown';
                          String age = userData['age']?.toString() ?? '-';

                          bool isOnline = userData['isOnline'] ?? false;

                          return GestureDetector(
                            onTap: () => _navigateToDetailedProfile(
                                context, memberIds[index]),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(10)),
                                    child: Image.network(
                                      profileImage,
                                      height: 125,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            CircleAvatar(
                                              radius: 4,
                                              backgroundColor: isOnline
                                                  ? Colors.green
                                                  : Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "$firstName, $age",
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
