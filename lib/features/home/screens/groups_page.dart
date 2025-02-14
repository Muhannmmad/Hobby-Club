import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hoppy_club/features/home/screens/detailed_profile_page.dart';
import 'package:hoppy_club/features/home/screens/event_screen.dart';

class GroupPage extends StatefulWidget {
  final String groupId;

  const GroupPage({super.key, required this.groupId});

  @override
  GroupPageState createState() => GroupPageState();
}

class GroupPageState extends State<GroupPage> {
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
        .listen((doc) async {
      if (doc.exists) {
        List<dynamic> members =
            (doc.data() as Map<String, dynamic>)['members'] ?? [];

        // Query Firestore for only valid users
        QuerySnapshot usersSnapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId,
                whereIn: members.isNotEmpty ? members : ['dummy_id'])
            .get();

        List<String> validMemberIds =
            usersSnapshot.docs.map((doc) => doc.id).toList();

        setState(() {
          memberIds = validMemberIds;
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
      ("Error toggling membership: $e");
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
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Group Members and Events",
          style: TextStyle(fontSize: screenWidth * 0.05),
        ),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const EventScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                ),
                child: Text(
                  "Events",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.04,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          Expanded(
              child: memberIds.isEmpty
                  ? Center(
                      child: Text(
                        "No members yet.",
                        style: TextStyle(fontSize: screenWidth * 0.04),
                      ),
                    )
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
                                'assets/profiles/profile.jpg';
                            String firstName =
                                userData['firstName'] ?? 'Unknown';
                            String age = userData['age']?.toString() ?? '-';
                            bool isOnline = userData['isOnline'] ?? false;

                            return GestureDetector(
                              onTap: () => _navigateToDetailedProfile(
                                  context, memberIds[index]),
                              child: Stack(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    height: double.infinity,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        profileImage,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return SizedBox(
                                              width: double.infinity,
                                              height: double.infinity,
                                              child: Image.asset(
                                                'assets/profiles/profile.jpg',
                                                fit: BoxFit.cover,
                                              ));
                                        },
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(6.0),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius:
                                            const BorderRadius.vertical(
                                          bottom: Radius.circular(10),
                                        ),
                                      ),
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
                                              Expanded(
                                                child: Text(
                                                  "$firstName, $age",
                                                  style: TextStyle(
                                                    fontSize:
                                                        screenWidth * 0.020,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.visible,
                                                ),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    )),
        ],
      ),
    );
  }
}
