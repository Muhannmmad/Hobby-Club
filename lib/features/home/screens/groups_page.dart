import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupPage extends StatefulWidget {
  final String groupId;

  const GroupPage({Key? key, required this.groupId}) : super(key: key);

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
      appBar: AppBar(title: Text("Group Page")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: isLoading ? null : _toggleMembership,
            child: isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : Text(isMember ? "Leave Group" : "Join Group"),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: memberIds.isEmpty
                ? Center(child: Text("No members yet."))
                : GridView.builder(
                    padding: const EdgeInsets.all(10),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 3 / 4, // Adjust for card proportions
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
                            return Center(child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData || snapshot.data == null) {
                            return SizedBox.shrink();
                          }

                          var userData =
                              snapshot.data!.data() as Map<String, dynamic>?;

                          if (userData == null) {
                            return SizedBox.shrink();
                          }

                          String name = userData['name'] ?? 'Unknown';
                          String city = userData['city'] ?? 'Unknown City';
                          String profilePic = userData['profilePic'] ??
                              'https://via.placeholder.com/150'; // Fallback image
                          String age = userData['age']?.toString() ?? '-';

                          return GestureDetector(
                            onTap: () => _navigateToDetailedProfile(
                                context, memberIds[index]),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundImage: NetworkImage(profilePic),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "$name, $age",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    city.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
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

class DetailedProfilePage extends StatelessWidget {
  final String userId;

  const DetailedProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Detailed Profile")),
      body: Center(
        child: Text("Display detailed profile for user ID: $userId"),
      ),
    );
  }
}
